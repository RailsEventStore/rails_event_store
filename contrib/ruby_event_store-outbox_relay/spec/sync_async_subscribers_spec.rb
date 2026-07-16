# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe "sync vs async subscribers" do
      helper = SpecHelper.new
      event_klass = RubyEventStore::ActiveRecord::WithDefaultModels.new.call.first

      around { |example| helper.run_lifecycle { example.run } }

      def build_client
        SpecHelper.new.extended_client_class.new(
          repository: RubyEventStore::ActiveRecord::EventRepository.new(serializer: RubyEventStore::Serializers::YAML),
        )
      end

      def build_relay(client)
        Relay.new(client: client, event_klass: RubyEventStore::ActiveRecord::WithDefaultModels.new.call.first)
      end

      specify "a sync subscriber is delivered immediately, before the relay ever runs" do
        client = build_client
        received = []
        client.subscribe_sync(->(event) { received << event }, to: [TestEvent])

        event = TestEvent.new
        client.publish(event)

        expect(received.map(&:event_id)).to eq([event.event_id])
      end

      specify "every published event is written with published_at: nil, regardless of subscribers" do
        client = build_client
        event = TestEvent.new

        client.publish(event)

        expect(event_klass.find_by!(event_id: event.event_id).published_at).to be_nil
      end

      specify "an async subscriber is not delivered synchronously, only after the relay processes the batch" do
        TestAsyncJob.reset!
        client = build_client
        client.subscribe_async(TestAsyncJob, to: [TestEvent])
        relay = build_relay(client)

        event = TestEvent.new
        client.publish(event)
        expect(TestAsyncJob.received).to be_empty

        relay.process_batch

        expect(TestAsyncJob.received.size).to eq(1)
        expect(TestAsyncJob.received.first["event_id"]).to eq(event.event_id)
      end

      specify "published_at is set once the relay has processed the event" do
        client = build_client
        client.subscribe_async(TestAsyncJob, to: [TestEvent])
        relay = build_relay(client)
        event = TestEvent.new
        client.publish(event)

        relay.process_batch

        expect(event_klass.find_by!(event_id: event.event_id).published_at).not_to be_nil
      end

      specify "sync and async subscribers on the same event both fire, each exactly once" do
        TestAsyncJob.reset!
        client = build_client
        sync_received = []
        client.subscribe_sync(->(event) { sync_received << event }, to: [TestEvent])
        client.subscribe_async(TestAsyncJob, to: [TestEvent])
        relay = build_relay(client)

        event = TestEvent.new
        client.publish(event)

        expect(sync_received.map(&:event_id)).to eq([event.event_id])
        expect(TestAsyncJob.received).to be_empty

        relay.process_batch
        relay.process_batch

        expect(sync_received.size).to eq(1)
        expect(TestAsyncJob.received.size).to eq(1)
      end

      specify "an event with no async subscribers is still picked up and marked published by the relay" do
        client = build_client
        relay = build_relay(client)
        event = TestEvent.new

        client.publish(event)
        processed = relay.process_batch

        expect(processed).to eq(1)
        expect(event_klass.find_by!(event_id: event.event_id).published_at).not_to be_nil
      end
    end
  end
end
