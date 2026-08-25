# frozen_string_literal: true

require "rails_event_store/inspector"
require "active_support"
require "active_support/notifications"

FakeEvent = Struct.new(:event_id, :event_type, :metadata)

def fake_event(id: "evt-1", type: "SomethingHappened", **metadata)
  FakeEvent.new(id, type, metadata)
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random

  config.before do
    RailsEventStore::Inspector.buffer.clear
    RailsEventStore::Inspector.instance_variable_set(:@configuration, nil)
    Thread.current[RailsEventStore::Inspector::ACTIVE] = nil
  end
end

def watching
  Thread.current[RailsEventStore::Inspector::ACTIVE] = true
  yield
ensure
  Thread.current[RailsEventStore::Inspector::ACTIVE] = nil
end
