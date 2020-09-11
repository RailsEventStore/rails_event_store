require 'spec_helper'
require 'action_controller/railtie'

AsyncAdapterAvailable = Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new("5.0.0")
SimpleAdapter = AsyncAdapterAvailable ? :async : :inline

module RailsEventStore
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

    let(:with_defaults) do
      Object.const_set("HandlerWithDefaults", Class.new(ActiveJob::Base) do
        cattr_accessor :event
        prepend RailsEventStore::AsyncHandler

        def perform(event)
          self.class.event = event
        end
      end)
    end
    let(:with_another_event_store) do
      Object.const_set("HandlerWithAnotherEventStore", Class.new(ActiveJob::Base) do
        cattr_accessor :event
        prepend RailsEventStore::AsyncHandler.with(event_store: another_event_store)

        def perform(event)
          self.class.event = event
        end
      end)
    end
    let(:with_specified_serializer) do
      Object.const_set("HandlerWithSpecifiedSerializer", Class.new(ActiveJob::Base) do
        cattr_accessor :event
        prepend RailsEventStore::AsyncHandler.with(event_store: json_event_store, serializer: JSON)

        def perform(event)
          self.class.event = event
        end
      end)
    end

    specify "with defauts" do
      handler = with_defaults.new

      expect(handler.event_store).to eq(Rails.configuration.event_store)
      expect(handler.serializer).to eq(YAML)

      with_defaults.event = nil
      event_store.subscribe_to_all_events(with_defaults)
      event_store.publish(ev = RailsEventStore::Event.new)
      wait_until{ with_defaults.event }
      expect(with_defaults.event).to eq(ev)
    end

    specify "with specified event store" do
      handler = with_another_event_store.new

      expect(handler.event_store).to eq(another_event_store)
      expect(handler.serializer).to eq(YAML)

      with_another_event_store.event = nil
      event_store.subscribe_to_all_events(with_another_event_store)
      event_store.publish(ev = RailsEventStore::Event.new)
      wait_until{ with_another_event_store.event }
      expect(with_another_event_store.event).to eq(ev)
    end

    specify "with specified serializer" do
      handler = with_specified_serializer.new

      expect(handler.event_store).to eq(json_event_store)
      expect(handler.serializer).to eq(JSON)

      with_specified_serializer.event = nil
      event_store.subscribe_to_all_events(with_specified_serializer)
      event_store.publish(ev = RailsEventStore::Event.new)
      wait_until{ with_specified_serializer.event }
      expect(with_specified_serializer.event).to eq(ev)
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
