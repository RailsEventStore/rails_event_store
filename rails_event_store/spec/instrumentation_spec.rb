require 'spec_helper'
require 'ruby_event_store/spec/dispatcher_lint'

module RailsEventStore
  DummyEvent = Class.new(RailsEventStore::Event)

  RSpec.describe InstrumentedDispatcher do
    specify do
      client  = Client.new(event_broker: EventBroker.new(dispatcher: InstrumentedDispatcher.new))
      event   = DummyEvent.new
      handler = Proc.new { }
      client.subscribe(handler, [DummyEvent])

      notifications = []
      callback = ->(name, started, finished, unique_id, data) do
        notifications << unique_id

        expect(data[:subscriber]).to eq(handler)
        expect(data[:event]).to      eq(event)
      end

      ActiveSupport::Notifications.subscribed(callback, "dispatch.rails_event_store") do
        client.publish_event(event)
      end

      expect(notifications.size).to eq(1)
    end
  end
end
