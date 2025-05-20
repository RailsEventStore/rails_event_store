# frozen_string_literal: true

require "spec_helper"
require "action_controller/railtie"
require_relative "../../support/helpers/silence_stdout"

SilenceStdout.silence_stdout { require "sidekiq/testing" }

module RailsEventStore
  class HandlerWithDefaults < ActiveJob::Base
    def perform(event)
      $queue.push(event)
    end
  end

  class HandlerWithAnotherEventStore < ActiveJob::Base
    def perform(event)
      $queue.push(event)
    end
  end

  class HandlerWithEventStoreLocator < ActiveJob::Base
    def perform(event)
      $queue.push(event)
    end
  end

  class HandlerWithSpecifiedSerializer < ActiveJob::Base
    def perform(event)
      $queue.push(event)
    end
  end

  class MyLovelyAsyncHandler < ActiveJob::Base
    def perform(payload)
      $queue.push(
        Rails.configuration.event_store.deserialize(
          serializer: RubyEventStore::Serializers::YAML,
          **payload.transform_keys(&:to_sym),
        ),
      )
    end
  end

  class HandlerWithHelper < ActiveJob::Base
    def perform(event)
      $queue.push(event)
    end
  end

  class MetadataHandler < ActiveJob::Base
    cattr_accessor :metadata

    def perform(_event)
      $queue.push(Rails.configuration.event_store.metadata)
    end
  end

  class IdOnlyHandler < ActiveJob::Base
    def perform(event)
      $queue.push(event)
    end
  end

  class YetAnotherIdOnlyHandler < ActiveJob::Base
    def perform(event)
      $queue.push(event)
    end
  end

  ::RSpec.describe AsyncHandler do
    let(:event_store) { RailsEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
    let(:another_event_store) { RailsEventStore::Client.new }
    let(:json_event_store) do
      RailsEventStore::Client.new(
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

    specify "default dispatcher can into ActiveJob" do
      event_store.subscribe_to_all_events(MyLovelyAsyncHandler)
      event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq(ev)
    end

    specify "ActiveJob with AsyncHandler prepended" do
      HandlerWithHelper.prepend RailsEventStore::AsyncHandler
      event_store.subscribe_to_all_events(HandlerWithHelper)
      event_store.publish(ev = RubyEventStore::Event.new)
      expect($queue.pop).to eq(ev)
    end

    specify "ActiveJob with CorrelatedHandler prepended" do
      with_correlated_handler do
        event_store.publish(ev = RubyEventStore::Event.new)
        expect($queue.pop).to eq({ correlation_id: ev.correlation_id, causation_id: ev.event_id })
      end
    end

    specify "ActiveJob with CorrelatedHandler prepended (2)" do
      with_correlated_handler do
        event_store.publish(ev = RubyEventStore::Event.new(metadata: { correlation_id: "COID", causation_id: "CAID" }))
        expect($queue.pop).to eq({ correlation_id: "COID", causation_id: ev.event_id })
      end
    end

    specify "ActiveJob with sidekiq adapter that requires serialization", mutant: false do
      ActiveJob::Base.queue_adapter = :sidekiq
      ev = RubyEventStore::Event.new
      Sidekiq::Testing.fake! do
        event_store.subscribe_to_all_events(MyLovelyAsyncHandler)
        event_store.publish(ev)
        Sidekiq::Worker.drain_all
      end
      expect($queue.pop(true)).to eq(ev)
    end

    specify "CorrelatedHandler with event not yet scheduled with correlation_id" do
      with_correlated_handler do
        event_store.append(ev = RubyEventStore::Event.new)
        ev = event_store.read.event(ev.event_id)

        handler.perform_now(serialize_without_correlation_id(ev))
        expect($queue.pop).to eq({ correlation_id: nil, causation_id: ev.event_id })
      end
    end

    specify "ActiveJob with AsyncHandlerJobIdOnly prepended" do
      with_test_handler(IdOnlyHandler) do |handler|
        handler.prepend AsyncHandlerJobIdOnly

        event_store.publish(ev = RubyEventStore::Event.new)
        expect($queue.pop).to eq(ev)
      end
    end

    specify "ActiveJob with AsyncHandlerJobIdOnly prepended with event store locator" do
      with_test_handler(IdOnlyHandler) do |handler|
        handler.prepend AsyncHandlerJobIdOnly.with(event_store: nil, event_store_locator: -> { event_store })

        event_store.publish(ev = RubyEventStore::Event.new)
        expect($queue.pop).to eq(ev)
      end
    end

    specify "ActiveJob with AsyncHandlerJobIdOnly prepended to host class" do
      with_test_handler(YetAnotherIdOnlyHandler) do |handler|
        handler.prepend AsyncHandlerJobIdOnly

        event_store.publish(ev = RubyEventStore::Event.new)
        expect($queue.pop).to eq(ev)
      end
    end

    private

    def with_test_handler(base_class)
      stub_const("TestHandler", Class.new(base_class)) do
        event_store.subscribe_to_all_events(TestHandler)
        yield TestHandler
      end
    end

    def with_correlated_handler
      with_test_handler(MetadataHandler) do |handler|
        handler.prepend RailsEventStore::CorrelatedHandler
        handler.prepend RailsEventStore::AsyncHandler

        yield handler
      end
    end

    def serialize_without_correlation_id(ev)
      serialized = event_store.__send__(:mapper).event_to_record(ev).serialize(RubyEventStore::Serializers::YAML).to_h
      serialized[:metadata] = "--- {}\n"
      serialized
    end
  end
end
