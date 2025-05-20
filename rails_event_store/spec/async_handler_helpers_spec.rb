# frozen_string_literal: true

require "spec_helper"
require "action_controller/railtie"
require_relative "../../support/helpers/silence_stdout"

SilenceStdout.silence_stdout { require "sidekiq/testing" }

module RailsEventStore
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

  class MetadataHandler < ActiveJob::Base
    cattr_accessor :metadata

    def perform(_event)
      $queue.push(Rails.configuration.event_store.metadata)
    end
  end

  ::RSpec.describe AsyncHandler do
    let(:event_store) { Client.new(repository: RubyEventStore::InMemoryRepository.new) }
    let(:another_event_store) { Client.new }
    let(:json_event_store) do
      Client.new(
        message_broker:
          RubyEventStore::Broker.new(
            dispatcher:
              RubyEventStore::ImmediateAsyncDispatcher.new(scheduler: ActiveJobScheduler.new(serializer: JSON)),
          ),
      )
    end

    around { |example| Timeout.timeout(2) { example.run } }

    around { |example| ActiveJob::Base.with(queue_adapter: :async) { example.run } }

    before do
      allow(Rails).to receive_message_chain(:application, :config).and_return(FakeConfiguration.new)
      Rails.configuration.event_store = event_store
      $queue = Queue.new
    end

    specify "with defaults" do
      with_test_handler do |handler|
        handler.prepend RailsEventStore::AsyncHandler.with(event_store: json_event_store, serializer: JSON)

        event_store.publish(ev = RubyEventStore::Event.new)
        expect($queue.pop).to eq(ev)
      end
    end

    specify "with specified event store" do
      with_test_handler do |handler|
        handler.prepend RailsEventStore::AsyncHandler.with(event_store: another_event_store)

        event_store.publish(ev = RubyEventStore::Event.new)
        expect($queue.pop).to eq(ev)
      end
    end

    specify "with specified event store locator" do
      with_test_handler do |handler|
        handler.prepend RailsEventStore::AsyncHandler.with(
                          event_store: nil,
                          event_store_locator: -> { another_event_store },
                        )

        another_event_store.publish(ev = RubyEventStore::Event.new)
        expect($queue.pop).to eq(ev)
      end
    end

    specify "with specified serializer" do
      with_test_handler do |handler|
        handler.prepend RailsEventStore::AsyncHandler.with(event_store: json_event_store, serializer: JSON)

        json_event_store.publish(ev = RubyEventStore::Event.new)
        expect($queue.pop).to eq(ev)
      end
    end

    specify "default dispatcher can into ActiveJob" do
      with_test_handler do |handler|
        handler.prepend RailsEventStore::AsyncHandler

        event_store.publish(ev = RubyEventStore::Event.new)
        expect($queue.pop).to eq(ev)
      end
    end

    specify "ActiveJob with AsyncHandler prepended" do
      with_test_handler do |handler|
        handler.prepend RailsEventStore::AsyncHandler

        event_store.publish(ev = RubyEventStore::Event.new)
        expect($queue.pop).to eq(ev)
      end
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
      with_test_handler do |handler|
        handler.prepend AsyncHandlerJobIdOnly

        event_store.publish(ev = RubyEventStore::Event.new)
        expect($queue.pop).to eq(ev)
      end
    end

    specify "ActiveJob with AsyncHandlerJobIdOnly prepended with event store locator" do
      with_test_handler do |handler|
        handler.prepend AsyncHandlerJobIdOnly.with(event_store: nil, event_store_locator: -> { event_store })

        event_store.publish(ev = RubyEventStore::Event.new)
        expect($queue.pop).to eq(ev)
      end
    end

    specify "ActiveJob with AsyncHandlerJobIdOnly prepended to host class" do
      with_test_handler do |handler|
        handler.prepend AsyncHandlerJobIdOnly

        event_store.publish(ev = RubyEventStore::Event.new)
        expect($queue.pop).to eq(ev)
      end
    end

    private

    def with_test_handler(base_class = ActiveJob::Base)
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
