# frozen_string_literal: true

require "spec_helper"
require "action_controller/railtie"

module RailsEventStore
  ::RSpec.describe AsyncHandler do
    before do
      allow(Rails).to receive_message_chain(:application, :config).and_return(FakeConfiguration.new)
      Rails.configuration.event_store = event_store

      $queue = Queue.new
    end

    around { |example| ActiveJob::Base.with(queue_adapter: :async) { example.run } }

    specify "ancestors" do
      with_test_handler do |handler|
        ancestors = handler.ancestors
        handler.prepend AsyncHandler

        expect(handler.ancestors - ancestors).to have_attributes(size: 2)
      end

      with_test_handler do |handler|
        ancestors = handler.ancestors
        handler.prepend AsyncHandler.with_defaults

        expect(handler.ancestors - ancestors).to have_attributes(size: 1)
      end

      with_test_handler do |handler|
        ancestors = handler.ancestors
        handler.prepend AsyncHandler.with(event_store_locator: -> { another_event_store })

        expect(handler.ancestors - ancestors).to have_attributes(size: 1)
      end
    end

    specify "with defaults" do
      with_test_handler do |handler|
        handler.prepend RailsEventStore::AsyncHandler

        event_store.subscribe_to_all_events(handler)
        event_store.publish(event)

        expect_to_receive(event)
      end
    end

    specify "with specified event store" do
      with_test_handler do |handler|
        handler.prepend RailsEventStore::AsyncHandler.with(event_store: another_event_store)

        event_store.subscribe_to_all_events(handler)
        event_store.publish(event)

        expect_to_receive(event)
      end
    end

    specify "with specified event store locator" do
      with_test_handler do |handler|
        handler.prepend RailsEventStore::AsyncHandler.with(
                          event_store: nil,
                          event_store_locator: -> { another_event_store },
                        )

        another_event_store.subscribe_to_all_events(handler)
        another_event_store.publish(event)

        expect_to_receive(event)
      end
    end

    specify "with specified serializer" do
      with_test_handler do |handler|
        handler.prepend RailsEventStore::AsyncHandler.with(event_store: json_event_store, serializer: JSON)

        json_event_store.subscribe_to_all_events(handler)
        json_event_store.publish(event)

        expect_to_receive(event)
      end
    end

    specify "ActiveJob with AsyncHandler prepended" do
      with_test_handler do |handler|
        handler.prepend RailsEventStore::AsyncHandler

        event_store.subscribe_to_all_events(handler)
        event_store.publish(event)

        expect_to_receive(event)
      end
    end

    specify "ActiveJob with CorrelatedHandler prepended" do
      with_correlated_handler do |handler|
        handler.prepend RailsEventStore::CorrelatedHandler
        handler.prepend RailsEventStore::AsyncHandler

        event_store.subscribe_to_all_events(handler)
        event_store.publish(event)

        expect_to_receive({ correlation_id: event.correlation_id, causation_id: event.event_id })
      end
    end

    specify "ActiveJob with CorrelatedHandler prepended (2)" do
      with_correlated_handler do |handler|
        handler.prepend RailsEventStore::CorrelatedHandler
        handler.prepend RailsEventStore::AsyncHandler

        event_store.subscribe_to_all_events(handler)
        event_store.publish(
          event = RubyEventStore::Event.new(metadata: { correlation_id: "COID", causation_id: "CAID" }),
        )

        expect_to_receive({ correlation_id: "COID", causation_id: event.event_id })
      end
    end

    specify "CorrelatedHandler with event not yet scheduled with correlation_id" do
      with_correlated_handler do |handler|
        handler.prepend RailsEventStore::CorrelatedHandler
        handler.prepend RailsEventStore::AsyncHandler

        event_store.append(event)
        read_event = event_store.read.event(event.event_id)
        handler.perform_now(serialize_without_correlation_id(read_event))

        expect_to_receive({ correlation_id: nil, causation_id: read_event.event_id })
      end
    end

    specify "ActiveJob with AsyncHandlerJobIdOnly prepended" do
      with_test_handler do |handler|
        handler.prepend AsyncHandlerJobIdOnly

        event_store.subscribe_to_all_events(handler)
        event_store.publish(event)

        expect_to_receive(event)
      end
    end

    specify "ActiveJob with AsyncHandlerJobIdOnly prepended with event store locator" do
      with_test_handler do |handler|
        handler.prepend AsyncHandlerJobIdOnly.with(event_store: nil, event_store_locator: -> { event_store })

        event_store.subscribe_to_all_events(handler)
        event_store.publish(event)

        expect_to_receive(event)
      end
    end

    specify "ActiveJob with AsyncHandlerJobIdOnly prepended to host class" do
      with_test_handler do |handler|
        handler.prepend AsyncHandlerJobIdOnly

        event_store.subscribe_to_all_events(handler)
        event_store.publish(event)

        expect_to_receive(event)
      end
    end

    specify "running inline via .perform_now" do
      with_test_handler do |handler|
        handler.prepend RailsEventStore::AsyncHandler

        handler.perform_now(event)

        expect_to_receive(event)
      end
    end

    specify "running inline via #perform_now" do
      with_test_handler do |handler|
        handler.prepend RailsEventStore::AsyncHandler

        handler.new(event).perform_now

        expect_to_receive(event)
      end
    end

    private

    let(:event) { RubyEventStore::Event.new }
    let(:event_store) { mk_event_store }
    let(:another_event_store) { mk_event_store }
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

    def with_correlated_handler
      stub_const(
        "TestHandler",
        Class.new(ActiveJob::Base) do
          def perform(event)
            $queue.push(Rails.configuration.event_store.metadata)
          end
        end,
      )
      yield TestHandler
    end

    def with_test_handler
      stub_const(
        "TestHandler",
        Class.new(ActiveJob::Base) do
          def perform(event)
            $queue.push(event)
          end
        end,
      )
      yield TestHandler
    end

    def mk_event_store = RailsEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)

    def expect_to_receive(something) = Timeout.timeout(2) { expect($queue.pop).to eq(something) }

    def serialize_without_correlation_id(ev)
      serialized =
        event_store.__send__(:mapper).events_to_records([ev]).first.serialize(RubyEventStore::Serializers::YAML).to_h
      serialized[:metadata] = "--- {}\n"
      serialized
    end
  end
end
