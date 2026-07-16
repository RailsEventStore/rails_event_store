# frozen_string_literal: true

require "spec_helper"
require "logger"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe Relay do
      helper = SpecHelper.new
      event_klass = RubyEventStore::ActiveRecord::WithDefaultModels.new.call.first

      around { |example| helper.run_lifecycle { example.run } }

      let(:async_broker) { RubyEventStore::Broker.new }
      let(:client) do
        helper.extended_client_class.new(
          repository: RubyEventStore::ActiveRecord::EventRepository.new(serializer: RubyEventStore::Serializers::YAML),
          async_broker: async_broker,
        )
      end
      let(:relay) do
        Relay.new(client: client, event_klass: event_klass, batch_size: 2, poll_interval: 0.01, logger: Logger.new(File::NULL))
      end

      def publish_async(n = 1)
        Array.new(n) { TestEvent.new }.each { |event| client.publish(event) }
      end

      specify "picks up an event, dispatches it to async_broker, and sets published_at" do
        received = []
        async_broker.add_global_subscription(->(event) { received << event })
        event = publish_async.first

        processed = relay.process_batch

        expect(processed).to eq(1)
        expect(received.map(&:event_id)).to eq([event.event_id])
        expect(event_klass.find_by!(event_id: event.event_id).published_at).not_to be_nil
      end

      specify "propagates correlation_id/causation_id from the persisted event into the broker.call context" do
        observed = {}
        async_broker.add_global_subscription(
          lambda do |_event|
            observed[:correlation_id] = client.metadata[:correlation_id]
            observed[:causation_id] = client.metadata[:causation_id]
          end,
        )
        event = publish_async.first

        relay.process_batch

        expect(observed[:correlation_id]).to eq(event.metadata[:correlation_id])
        expect(observed[:causation_id]).to eq(event.event_id)
      end

      specify "does not publish an already published event again (published_at already set)" do
        received = []
        async_broker.add_global_subscription(->(event) { received << event })
        publish_async

        relay.process_batch
        second_run = relay.process_batch

        expect(second_run).to eq(0)
        expect(received.size).to eq(1)
      end

      specify "leaves published_at NULL when broker.call raises, so the event is retried" do
        async_broker.add_global_subscription(->(_event) { raise "boom" })
        event = publish_async.first

        expect { relay.process_batch }.to raise_error("boom")

        expect(event_klass.find_by!(event_id: event.event_id).published_at).to be_nil
      end

      specify "processes events in id order and respects batch_size" do
        received = []
        async_broker.add_global_subscription(->(event) { received << event })
        events = publish_async(5) # relay's batch_size (see let above) is 2

        processed = relay.process_batch

        expect(processed).to eq(2)
        expect(received.map(&:event_id)).to eq(events.first(2).map(&:event_id))
        expect(event_klass.where(published_at: nil).count).to eq(3)
      end

      specify "an event reaches an async subscriber exactly once" do
        received = []
        async_broker.add_global_subscription(->(event) { received << event })
        event = publish_async.first

        relay.process_batch
        relay.process_batch

        expect(received.map(&:event_id)).to eq([event.event_id])
      end
    end
  end
end
