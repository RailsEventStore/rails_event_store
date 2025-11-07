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

module IdentityAndAccess
  SomethingHappened = Class.new(RubyEventStore::Event)
  SomeoneDidThing = Class.new(RubyEventStore::Event)
  ThingConfirmed = Class.new(RubyEventStore::Event)
  ThingRejected = Class.new(RubyEventStore::Event)
end

module Subscriptions
  SomethingHappened = Class.new(RubyEventStore::Event)
  SomeoneDidThing = Class.new(RubyEventStore::Event)
  ThingConfirmed = Class.new(RubyEventStore::Event)
  ThingRejected = Class.new(RubyEventStore::Event)
end

module Payments
  SomethingHappened = Class.new(RubyEventStore::Event)
  SomeoneDidThing = Class.new(RubyEventStore::Event)
  ThingConfirmed = Class.new(RubyEventStore::Event)
  ThingRejected = Class.new(RubyEventStore::Event)
end

module Accounting
  SomethingHappened = Class.new(RubyEventStore::Event)
  SomeoneDidThing = Class.new(RubyEventStore::Event)
  ThingConfirmed = Class.new(RubyEventStore::Event)
  ThingRejected = Class.new(RubyEventStore::Event)
end

module Banking
  SomethingHappened = Class.new(RubyEventStore::Event)
  SomeoneDidThing = Class.new(RubyEventStore::Event)
  ThingConfirmed = Class.new(RubyEventStore::Event)
  ThingRejected = Class.new(RubyEventStore::Event)
end

# Reporting namespace intentionally not defined - these will use event_type metadata for testing

sample_event_class =
  lambda do
    namespaces = %w[IdentityAndAccess Subscriptions Payments Accounting Banking]
    events = %w[SomethingHappened SomeoneDidThing ThingConfirmed ThingRejected]

    namespace = namespaces.sample
    event = events.sample
    Object.const_get("#{namespace}::#{event}")
  end

sample_event_type_without_class =
  lambda do
    events = %w[SomethingHappened SomeoneDidThing ThingConfirmed ThingRejected]
    "Reporting::#{events.sample}"
  end

event_store.publish(
  80
    .times
    .map { sample_event_class.call.new(data: sample_data) } +
    10.times.map { RubyEventStore::Event.new(data: sample_data, metadata: { event_type: sample_event_type_without_class.call }) },
  stream_name: "DummyStream$78",
)

other_event = sample_event_class.call.new(data: sample_data, metadata: { correlation_id: "469904c5-46ee-43a3-857f-16a455cfe337" })

event_store.publish(other_event, stream_name: "OtherStream$91")
21.times do
  event_store.with_metadata(
    correlation_id: other_event.metadata[:correlation_id] || other_event.event_id,
    causation_id: other_event.event_id,
  ) do
    event_store.publish(sample_event_class.call.new(data: sample_data), stream_name: "DummyStream$79")
  end
end

RELATED_STREAMS_QUERY = ->(stream_name) do
  stream_name.start_with?("$by_type_#{sample_event_class.call.name}") ? %w[all $by_type_#{sample_event_class.call.name}] : []
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
