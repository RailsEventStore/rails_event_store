require 'spec_helper'
require 'action_controller/railtie'

AsyncAdapterAvailable = Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new("5.0.0")
SimpleAdapter = AsyncAdapterAvailable ? :async : :inline

module RailsEventStore
  class HandlerWithDefaults < ActiveJob::Base
    cattr_accessor :event

    def perform(event)
      self.class.event = event
    end
  end

  class HandlerWithAnotherEventStore < ActiveJob::Base
    cattr_accessor :event

    def perform(event)
      self.class.event = event
    end
  end

  class HandlerWithSpecifiedSerializer < ActiveJob::Base
    cattr_accessor :event

    def perform(event)
      self.class.event = event
    end
  end

  RSpec.describe AsyncHandler do
    let(:event_store) { RailsEventStore::Client.new }
    let(:another_event_store) { RailsEventStore::Client.new }
    let(:json_event_store) {
      RailsEventStore::Client.new(
        dispatcher: RubyEventStore::ImmediateAsyncDispatcher.new(
          scheduler: ActiveJobScheduler.new(serializer: JSON)
        ),
      )
    }
    let(:application) { instance_double(Rails::Application) }
    let(:config)      { FakeConfiguration.new }

    before do
      allow(Rails).to       receive(:application).and_return(application)
      allow(application).to receive(:config).and_return(config)
      Rails.configuration.event_store = event_store
      ActiveJob::Base.queue_adapter   = SimpleAdapter
    end

    specify "with defauts" do
      HandlerWithDefaults.prepend RailsEventStore::AsyncHandler
      handler = HandlerWithDefaults.new

      expect(handler.event_store).to eq(Rails.configuration.event_store)
      expect(handler.serializer).to eq(YAML)

      HandlerWithDefaults.event = nil
      event_store.subscribe_to_all_events(HandlerWithDefaults)
      event_store.publish(ev = RailsEventStore::Event.new)
      wait_until{ HandlerWithDefaults.event }
      expect(HandlerWithDefaults.event).to eq(ev)
    end

    specify "with specified event store" do
      HandlerWithAnotherEventStore.prepend RailsEventStore::AsyncHandler.with(event_store: another_event_store)
      handler = HandlerWithAnotherEventStore.new

      expect(handler.event_store).to eq(another_event_store)
      expect(handler.serializer).to eq(YAML)

      HandlerWithAnotherEventStore.event = nil
      event_store.subscribe_to_all_events(HandlerWithAnotherEventStore)
      event_store.publish(ev = RailsEventStore::Event.new)
      wait_until{ HandlerWithAnotherEventStore.event }
      expect(HandlerWithAnotherEventStore.event).to eq(ev)
    end

    specify "with specified serializer" do
      HandlerWithSpecifiedSerializer.prepend RailsEventStore::AsyncHandler.with(event_store: json_event_store, serializer: JSON)
      handler = HandlerWithSpecifiedSerializer.new

      expect(handler.event_store).to eq(json_event_store)
      expect(handler.serializer).to eq(JSON)

      HandlerWithSpecifiedSerializer.event = nil
      json_event_store.subscribe_to_all_events(HandlerWithSpecifiedSerializer)
      json_event_store.publish(ev = RailsEventStore::Event.new)
      wait_until{ HandlerWithSpecifiedSerializer.event }
      expect(HandlerWithSpecifiedSerializer.event).to eq(ev)
    end

    private

    def wait_until(&block)
      Timeout.timeout(1) do
        loop do
          break if block.call
          sleep(0.001)
        end
      end
    end
  end
end
