# frozen_string_literal: true

require "spec_helper"
require "action_controller/railtie"

module RailsEventStore
  %w[
    HandlerWithDefaults
    HandlerWithAnotherEventStore
    HandlerWithEventStoreLocator
    HandlerWithSpecifiedSerializer
    HandlerWithHelper
    IdOnlyHandler
    YetAnotherIdOnlyHandler
  ].each { |name| const_set(name, Class.new(ActiveJob::Base) { def perform(event) = $queue.push(event) }) }

  class MetadataHandler < ActiveJob::Base
    cattr_accessor :metadata

    def perform(_event)
      $queue.push(Rails.configuration.event_store.metadata)
    end
  end

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

    around { |example| Timeout.timeout(2) { example.run } }

    before do
      allow(Rails).to receive(:application).and_return(application)
      allow(application).to receive(:config).and_return(config)
      Rails.configuration.event_store = event_store
      ActiveJob::Base.queue_adapter = :async
      $queue = Queue.new
    end

    specify "with defaults" do
      HandlerWithDefaults.prepend RailsEventStore::AsyncHandler
      event_store.subscribe_to_all_events(HandlerWithDefaults)
      event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq(ev)
    end

    specify "with specified event store" do
      HandlerWithAnotherEventStore.prepend RailsEventStore::AsyncHandler.with(event_store: another_event_store)
      event_store.subscribe_to_all_events(HandlerWithAnotherEventStore)
      event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq(ev)
    end

    specify "with specified event store locator" do
      HandlerWithEventStoreLocator.prepend RailsEventStore::AsyncHandler.with(
                                             event_store: nil,
                                             event_store_locator: -> { another_event_store },
                                           )
      another_event_store.subscribe_to_all_events(HandlerWithEventStoreLocator)
      another_event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq(ev)
    end

    specify "with specified serializer" do
      HandlerWithSpecifiedSerializer.prepend RailsEventStore::AsyncHandler.with(
                                               event_store: json_event_store,
                                               serializer: JSON,
                                             )
      json_event_store.subscribe_to_all_events(HandlerWithSpecifiedSerializer)
      json_event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq(ev)
    end

    specify "ActiveJob with AsyncHandler prepended" do
      HandlerWithHelper.prepend RailsEventStore::AsyncHandler
      event_store.subscribe_to_all_events(HandlerWithHelper)
      event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq(ev)
    end

    specify "ActiveJob with CorrelatedHandler prepended" do
      HandlerA = Class.new(MetadataHandler)
      HandlerA.prepend RailsEventStore::CorrelatedHandler
      HandlerA.prepend RailsEventStore::AsyncHandler
      event_store.subscribe_to_all_events(HandlerA)
      event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq({ correlation_id: ev.correlation_id, causation_id: ev.event_id })
    end

    specify "ActiveJob with CorrelatedHandler prepended (2)" do
      HandlerB = Class.new(MetadataHandler)
      HandlerB.prepend RailsEventStore::CorrelatedHandler
      HandlerB.prepend RailsEventStore::AsyncHandler
      event_store.subscribe_to_all_events(HandlerB)
      event_store.publish(ev = RubyEventStore::Event.new(metadata: { correlation_id: "COID", causation_id: "CAID" }))
      expect($queue.pop).to eq({ correlation_id: "COID", causation_id: ev.event_id })
    end

    specify "CorrelatedHandler with event not yet scheduled with correlation_id" do
      HandlerB = Class.new(MetadataHandler)
      HandlerB.prepend RailsEventStore::CorrelatedHandler
      HandlerB.prepend RailsEventStore::AsyncHandler
      event_store.append(ev = RubyEventStore::Event.new)
      ev = event_store.read.event(ev.event_id)
      HandlerB.perform_now(serialize_without_correlation_id(ev))
      expect($queue.pop).to eq({ correlation_id: nil, causation_id: ev.event_id })
    end

    specify "ActiveJob with AsyncHandlerJobIdOnly prepended" do
      HandlerD = Class.new(IdOnlyHandler)
      HandlerD.prepend AsyncHandlerJobIdOnly
      event_store.subscribe_to_all_events(HandlerD)
      event_store.publish(ev = RubyEventStore::Event.new)

      expect($queue.pop).to eq(ev)
    end

    specify "ActiveJob with AsyncHandlerJobIdOnly prepended with event store locator" do
      HandlerE = Class.new(IdOnlyHandler)
      HandlerE.prepend AsyncHandlerJobIdOnly.with(event_store: nil, event_store_locator: -> { event_store })
      event_store.subscribe_to_all_events(HandlerE)
      event_store.publish(ev = RubyEventStore::Event.new)

      expect($queue.pop).to eq(ev)
    end

    specify "ActiveJob with AsyncHandlerJobIdOnly prepended to host class" do
      YetAnotherIdOnlyHandler.prepend AsyncHandlerJobIdOnly
      event_store.subscribe_to_all_events(YetAnotherIdOnlyHandler)
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
