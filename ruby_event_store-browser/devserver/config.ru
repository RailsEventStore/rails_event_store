require 'ruby_event_store'
require_relative "../lib/ruby_event_store/browser/app"

repository = RubyEventStore::InMemoryRepository.new
event_store = RubyEventStore::Client.new(repository: repository)

DummyEvent = Class.new(::RubyEventStore::Event)
90.times do
  event_store.publish(DummyEvent.new(
    data: {
      some_integer_attribute: 42,
      some_string_attribute: "foobar",
      some_float_attribute: 3.14,
    }
  ), stream_name: "DummyStream$78")
end

run RubyEventStore::Browser::App.for(
  event_store_locator: -> { event_store },
  environment: :development
)
