require 'ruby_event_store'
require_relative "../lib/ruby_event_store/browser/app"

repository = RubyEventStore::InMemoryRepository.new
event_store = RubyEventStore::Client.new(repository: repository)

event_store.subscribe_to_all_events(RubyEventStore::LinkByCorrelationId.new(event_store: event_store))
event_store.subscribe_to_all_events(RubyEventStore::LinkByCausationId.new(event_store: event_store))
event_store.subscribe_to_all_events(RubyEventStore::LinkByEventType.new(event_store: event_store))

DummyEvent = Class.new(::RubyEventStore::Event)
OtherEvent = Class.new(::RubyEventStore::Event)

90.times do
  event_store.publish(DummyEvent.new(
    data: {
      some_integer_attribute: 42,
      some_string_attribute: "foobar",
      some_float_attribute: 3.14,
    }
  ), stream_name: "DummyStream$78")
end


some_correlation_id = "469904c5-46ee-43a3-857f-16a455cfe337"
other_event = OtherEvent.new(
  data: {
    some_integer_attribute: 42,
    some_string_attribute: "foobar",
    some_float_attribute: 3.14,
  },
  metadata: {
    correlation_id: some_correlation_id,
  },
)
event_store.publish(other_event, stream_name: "OtherStream$91")
21.times do
  event_store.with_metadata(
    correlation_id: other_event.metadata[:correlation_id] || other_event.event_id,
    causation_id: other_event.event_id
  ) do
    event_store.publish(DummyEvent.new(
      data: {
        some_integer_attribute: 42,
        some_string_attribute: "foobar",
        some_float_attribute: 3.14,
      },
    ), stream_name: "DummyStream$79")
  end
end

RELATED_STREAMS_QUERY = ->(stream_name) do
  if stream_name.start_with?("$by_type_DummyEvent")
    [
      "all",
      "$by_type_OtherEvent"
    ]
  else
    []
  end
end

browser_app = RubyEventStore::Browser::App.for(
  event_store_locator: -> { event_store },
  related_streams_query: RELATED_STREAMS_QUERY,
)
mount_point = "/"
run (Rack::Builder.new do
  map mount_point do
    run browser_app
  end
end)
