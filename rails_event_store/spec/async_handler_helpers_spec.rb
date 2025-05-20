# frozen_string_literal: true

require "spec_helper"
require "action_controller/railtie"

module RailsEventStore
  ::RSpec.describe AsyncHandler do
    let(:event_store) { RailsEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
    let(:another_event_store) { RailsEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
    let(:json_event_store) do
      RailsEventStore::Client.new(
        repository: RubyEventStore::InMemoryRepository.new,
        message_broker:
          RubyEventStore::Broker.new(
            dispatcher:
              RubyEventStore::ImmediateAsyncDispatcher.new(scheduler: ActiveJobScheduler.new(serializer: JSON)),
          ),
      )
    end
    let(:application) { instance_double(Rails::Application) }
    let(:config) { FakeConfiguration.new }

    before do
      stub_const("TestHandler", Class.new(ActiveJob::Base) { def perform(event) = $queue.push(event) })
      stub_const(
        "MetadataHandler",
        Class.new(ActiveJob::Base) { def perform(event) = $queue.push(Rails.configuration.event_store.metadata) },
      )
    end

    around { |example| Timeout.timeout(2) { example.run } }

    before do
      allow(Rails).to receive(:application).and_return(application)
      allow(application).to receive(:config).and_return(config)
      Rails.configuration.event_store = event_store
      ActiveJob::Base.queue_adapter = :async
      $queue = Queue.new
    end

    specify "with defaults" do
      TestHandler.prepend RailsEventStore::AsyncHandler
      event_store.subscribe_to_all_events(TestHandler)
      event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq(ev)
    end

    specify "with specified event store" do
      TestHandler.prepend RailsEventStore::AsyncHandler.with(event_store: another_event_store)
      event_store.subscribe_to_all_events(TestHandler)
      event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq(ev)
    end

    specify "with specified event store locator" do
      TestHandler.prepend RailsEventStore::AsyncHandler.with(
                            event_store: nil,
                            event_store_locator: -> { another_event_store },
                          )
      another_event_store.subscribe_to_all_events(TestHandler)
      another_event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq(ev)
    end

    specify "with specified serializer" do
      TestHandler.prepend RailsEventStore::AsyncHandler.with(event_store: json_event_store, serializer: JSON)
      json_event_store.subscribe_to_all_events(TestHandler)
      json_event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq(ev)
    end

    specify "ActiveJob with AsyncHandler prepended" do
      TestHandler.prepend RailsEventStore::AsyncHandler
      event_store.subscribe_to_all_events(TestHandler)
      event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq(ev)
    end

    specify "ActiveJob with CorrelatedHandler prepended" do
      MetadataHandler.prepend RailsEventStore::CorrelatedHandler
      MetadataHandler.prepend RailsEventStore::AsyncHandler
      event_store.subscribe_to_all_events(MetadataHandler)
      event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq({ correlation_id: ev.correlation_id, causation_id: ev.event_id })
    end

    specify "ActiveJob with CorrelatedHandler prepended (2)" do
      MetadataHandler.prepend RailsEventStore::CorrelatedHandler
      MetadataHandler.prepend RailsEventStore::AsyncHandler
      event_store.subscribe_to_all_events(MetadataHandler)
      event_store.publish(ev = RubyEventStore::Event.new(metadata: { correlation_id: "COID", causation_id: "CAID" }))
      expect($queue.pop).to eq({ correlation_id: "COID", causation_id: ev.event_id })
    end

    specify "CorrelatedHandler with event not yet scheduled with correlation_id" do
      MetadataHandler.prepend RailsEventStore::CorrelatedHandler
      MetadataHandler.prepend RailsEventStore::AsyncHandler
      event_store.append(ev = RubyEventStore::Event.new)
      ev = event_store.read.event(ev.event_id)
      MetadataHandler.perform_now(serialize_without_correlation_id(ev))
      expect($queue.pop).to eq({ correlation_id: nil, causation_id: ev.event_id })
    end

    specify "ActiveJob with AsyncHandlerJobIdOnly prepended" do
      TestHandler.prepend AsyncHandlerJobIdOnly
      event_store.subscribe_to_all_events(TestHandler)

      event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq(ev)
    end

    specify "ActiveJob with AsyncHandlerJobIdOnly prepended with event store locator" do
      TestHandler.prepend AsyncHandlerJobIdOnly.with(event_store: nil, event_store_locator: -> { event_store })
      event_store.subscribe_to_all_events(TestHandler)

      event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq(ev)
    end

    specify "ActiveJob with AsyncHandlerJobIdOnly prepended to host class" do
      TestHandler.prepend AsyncHandlerJobIdOnly
      event_store.subscribe_to_all_events(TestHandler)

      event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq(ev)
    end

    private

    def serialize_without_correlation_id(ev)
      serialized = event_store.__send__(:mapper).event_to_record(ev).serialize(RubyEventStore::Serializers::YAML).to_h
      serialized[:metadata] = "--- {}\n"
      serialized
    end
  end
end
