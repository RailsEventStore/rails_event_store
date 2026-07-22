# frozen_string_literal: true

require "ruby_event_store"
require_relative "../lib/ruby_event_store/browser/app"
require_relative "../spec/support/csp_app"

event_store = RubyEventStore::Client.new

event_store.subscribe_to_all_events(RubyEventStore::LinkByCorrelationId.new(event_store: event_store))
event_store.subscribe_to_all_events(RubyEventStore::LinkByCausationId.new(event_store: event_store))
event_store.subscribe_to_all_events(RubyEventStore::LinkByEventType.new(event_store: event_store))

sample_data = {
  some_integer_attribute: 42,
  some_string_attribute: "foobar",
  some_float_attribute: 3.14,
  some_float_infinity_attribute: 1.0 / 0,
}

sample_event_type =
  lambda do
    namespaces = %w[IdentityAndAccess Subscriptions Payments Accounting Banking Reporting]

    events = %w[SomethingHappened SomeoneDidThing ThingConfirmed ThingRejected]

    [namespaces.sample, events.sample].join("::")
  end

# Spread events across a realistic time range instead of publishing them all
# within the same millisecond — mixes tight bursts (sub-second gaps, to
# exercise the swimlane's same-timestamp grouping) with sparser gaps (up to a
# minute), across several streams with different endpoints so the compare
# view has plenty to line up.
GAP_POOL = [0.002, 0.01, 0.05, 0.2, 1, 3, 8, 20, 45].freeze

seed_stream =
  lambda do |stream_name, count:, end_at:|
    gaps = Array.new(count) { GAP_POOL.sample * rand }
    time = end_at - gaps.sum

    gaps.each do |gap|
      time += gap
      event = RubyEventStore::Event.new(data: sample_data, metadata: { event_type: sample_event_type.call })
      event.metadata[:timestamp] = time
      event.metadata[:valid_at] = time
      event_store.publish(event, stream_name: stream_name)
    end
  end

now = Time.now.utc
seed_stream.call("DummyStream$78", count: 300, end_at: now)
seed_stream.call("DummyStream$79", count: 220, end_at: now - 12)
seed_stream.call("DummyStream$80", count: 180, end_at: now - 40)

other_event =
  RubyEventStore::Event.new(
    data: sample_data,
    metadata: {
      event_type: sample_event_type.call,
      correlation_id: "469904c5-46ee-43a3-857f-16a455cfe337",
    },
  )

event_store.publish(other_event, stream_name: "OtherStream$91")
21.times do
  event_store.with_metadata(
    correlation_id: other_event.metadata[:correlation_id] || other_event.event_id,
    causation_id: other_event.event_id,
  ) do
    event_store.publish(
      RubyEventStore::Event.new(data: sample_data, metadata: { event_type: sample_event_type.call }),
      stream_name: "DummyStream$79",
    )
  end
end

RELATED_STREAMS_QUERY = ->(stream_name) do
  stream_name.start_with?("$by_type_#{sample_event_type.call}") ? %w[all $by_type_#{sample_event_type.call}] : []
end

browser_app =
  RubyEventStore::Browser::App.for(
    event_store_locator: -> { event_store },
    related_streams_query: RELATED_STREAMS_QUERY,
  )
mount_point = "/"

run(
  Rack::Builder.new do
    map mount_point do
      run CspApp.new(browser_app, "script-src 'self'; style-src 'self'")
    end
  end,
)
