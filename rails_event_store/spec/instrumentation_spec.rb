require 'spec_helper'
require 'ruby_event_store/spec/dispatcher_lint'

module RailsEventStore
  DummyEvent = Class.new(RailsEventStore::Event)

  RSpec.describe Dispatcher do
    specify do
      client  = Client.new(event_broker: EventBroker.new(dispatcher: Dispatcher.new))
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

  RSpec.describe Client do
    specify do
      client = Client.new
      event  = DummyEvent.new

      notifications = []
      callback = ->(name, started, finished, unique_id, data) do
        notifications << unique_id

        expect(data[:event]).to eq(event)
      end

      ActiveSupport::Notifications.subscribed(callback, "publish_event.rails_event_store") do
        client.publish_event(event)
      end

      expect(notifications.size).to eq(1)
    end
  end

  RSpec.describe "it works with typical legacy codebase scenarios" do
    specify do
      client = Client.new
      subscriber = ActiveSupport::Notifications.subscribe(/rails_event_store/, ->(*) { raise })

      ActiveRecord::Base.transaction do
        client.publish_event(DummyEvent.new)
      end

      ActiveSupport::Notifications.unsubscribe(subscriber)
      expect(client.read_all_streams_backward).not_to be_empty
    end
  end
end
