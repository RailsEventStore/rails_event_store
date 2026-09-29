# frozen_string_literal: true

require "spec_helper"
require "logger"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe Relay do
      helper = SpecHelper.new
      event_klass = RubyEventStore::ActiveRecord::WithDefaultModels.new.call.first

      around { |example| helper.run_lifecycle { example.run } }

      let(:now) { Time.utc(2026, 9, 29, 12, 0, 0) }
      let(:clock) { -> { now } }
      let(:client) { helper.extended_client_class.new(repository: helper.repository, async_subscriptions: helper.sync_subscriptions) }
      let(:retry_policy) { RetryPolicy.new(max_attempts: 3, jitter: 0) }

      let(:log) { StringIO.new }

      def build_relay(batch_size: 10, clock: self.clock)
        Relay.new(
          client: client,
          batch_size: batch_size,
          lease_duration: 60,
          retry_policy: retry_policy,
          clock: clock,
          logger: Logger.new(log),
        )
      end

      def publish(event = TestEvent.new, **kwargs)
        client.publish(event, **kwargs)
        event
      end

      describe "#process_batch" do
        specify "delivers a published event to its async subscriber and removes the message" do
          handler = recording_handler("OrderReport")
          client.subscribe_async(handler, to: [TestEvent])
          event = publish

          result = build_relay.process_batch

          expect(result).to eq(Relay::BatchResult.new(claimed: 1, delivered: 1, retried: 0, dead: 0))
          expect(handler.received.map(&:event_id)).to eq([event.event_id])
          expect(Message.count).to eq(0)
        end

        specify "reads the events of a whole batch with a single query" do
          client.subscribe_async(recording_handler("OrderReport"), to: [TestEvent])
          3.times { publish }
          allow(client).to receive(:read).and_call_original

          build_relay.process_batch

          expect(client).to have_received(:read).once
        end

        specify "reads an event once for all its subscribers in the same batch" do
          client.subscribe_async(recording_handler("First"), to: [TestEvent])
          client.subscribe_async(recording_handler("Second"), to: [TestEvent])
          event = publish
          specification = client.read
          allow(client).to receive(:read).and_return(specification)
          allow(specification).to receive(:events).and_call_original

          build_relay.process_batch

          expect(specification).to have_received(:events).with([event.event_id]).once
        end

        specify "delivers the event as read from the event store, with data and metadata intact" do
          handler = recording_handler("OrderReport")
          client.subscribe_async(handler, to: [TestEvent])
          event = publish(TestEvent.new(data: { "order_id" => 42 }, metadata: { tenant: "acme" }))

          build_relay.process_batch

          delivered = handler.received.first
          expect(delivered).to eq(event)
          expect(delivered.data).to eq({ "order_id" => 42 })
          expect(delivered.metadata[:tenant]).to eq("acme")
        end

        specify "delivers a record matching the event, as the synchronous path does" do
          records = []
          dispatcher = RubyEventStore::SyncScheduler.new
          dispatcher.define_singleton_method(:call) { |_subscriber, _event, record| records << record }
          client =
            helper.extended_client_class.new(
              repository: helper.repository,
              async_subscriptions: AsyncSubscriptions.new(dispatcher: dispatcher),
            )
          client.subscribe_async(recording_handler("OrderReport"), to: [TestEvent])
          event = TestEvent.new(data: { "order_id" => 42 })
          client.publish(event)

          Relay.new(client: client, logger: Logger.new(File::NULL)).process_batch

          expect(records.map(&:event_id)).to eq([event.event_id])
          expect(records.first.data).to eq({ "order_id" => 42 })
        end

        specify "reproduces correlation_id and causation_id around the dispatch" do
          observed = {}
          handler =
            recording_handler("OrderReport") do |_event|
              observed.merge!(client.metadata.slice(:correlation_id, :causation_id))
            end
          client.subscribe_async(handler, to: [TestEvent])
          event = publish

          build_relay.process_batch

          expect(observed).to eq(correlation_id: event.metadata[:correlation_id], causation_id: event.event_id)
          expect(client.metadata).to eq({})
        end

        specify "dispatches with no transaction open, so enqueued jobs are never deferred past the message removal" do
          transaction_open = nil
          handler = recording_handler("OrderReport") { |_event| transaction_open = Message.connection.transaction_open? }
          client.subscribe_async(handler, to: [TestEvent])
          publish

          build_relay.process_batch

          expect(transaction_open).to eq(false)
        end

        specify "delivers to the subscribers of the topic given to publish, not of the event type" do
          topic_handler = recording_handler("TopicHandler")
          type_handler = recording_handler("TypeHandler")
          client.subscribe_async(topic_handler, to: ["custom.topic"])
          client.subscribe_async(type_handler, to: [TestEvent])
          event = publish(topic: "custom.topic")

          build_relay.process_batch

          expect(topic_handler.received.map(&:event_id)).to eq([event.event_id])
          expect(type_handler.received).to be_empty
        end

        specify "a failing subscriber does not cause redelivery to the other subscribers of the same event" do
          healthy = recording_handler("Healthy")
          failing = recording_handler("Failing") { |_event| raise "boom" }
          client.subscribe_async(healthy, to: [TestEvent])
          client.subscribe_async(failing, to: [TestEvent])
          publish

          build_relay.process_batch
          build_relay(clock: -> { now + 3600 }).process_batch

          expect(healthy.received.size).to eq(1)
          expect(Message.pluck(:subscriber)).to eq(["Failing"])
        end

        specify "reschedules a failed dispatch with the retry policy's delay, recording the attempt and the error" do
          client.subscribe_async(recording_handler("Failing") { |_event| raise ArgumentError, "boom" }, to: [TestEvent])
          publish

          result = build_relay.process_batch

          expect(result).to eq(Relay::BatchResult.new(claimed: 1, delivered: 0, retried: 1, dead: 0))
          message = Message.sole
          expect(message.attempts).to eq(1)
          expect(message.next_attempt_at).to eq(now + 1)
          expect(message.last_error).to eq("ArgumentError: boom")
          expect(log.string).to include(
            "WARN -- : Outbox message #{message.id} (event #{message.event_id}, Failing) failed " \
              "attempt 1/3, next at 2026-09-29T12:00:01Z: ArgumentError\n",
          )
        end

        specify "does not retry a rescheduled message before it's due" do
          handler = recording_handler("Failing") { |_event| raise "boom" }
          client.subscribe_async(handler, to: [TestEvent])
          publish
          build_relay.process_batch

          expect(build_relay.process_batch.claimed).to eq(0)
          expect(build_relay(clock: -> { now + 1 }).process_batch.claimed).to eq(1)
        end

        specify "moves a message to the dead letters once the retry policy gives up" do
          client.subscribe_async(recording_handler("Failing") { |_event| raise ArgumentError, "boom" }, to: [TestEvent])
          event = publish
          enqueued_at = Message.sole.created_at
          message_id = Message.sole.id

          results = [0, 1, 3].map { |offset| build_relay(clock: -> { now + offset }).process_batch }

          expect(results.map(&:dead)).to eq([0, 0, 1])
          expect(Message.count).to eq(0)
          dead_letter = DeadLetter.sole
          expect(dead_letter).to have_attributes(
            event_id: event.event_id,
            topic: "TestEvent",
            subscriber: "Failing",
            attempts: 3,
            error_class: "ArgumentError",
            error_message: "boom",
            first_enqueued_at: enqueued_at,
            dead_at: now + 3,
          )
          expect(dead_letter.backtrace).to include("relay_spec.rb")
          expect(log.string).to include(
            "ERROR -- : Outbox message #{message_id} (event #{event.event_id}, Failing) " \
              "moved to dead letters after 3 attempt(s): ArgumentError\n",
          )
        end

        specify "dead-letters a dispatch error the retry policy treats as permanent on first occurrence" do
          permanent_error = Class.new(StandardError)
          stub_const("PermanentError", permanent_error)
          client.subscribe_async(recording_handler("Failing") { |_event| raise permanent_error }, to: [TestEvent])
          publish
          retry_policy = RetryPolicy.new(permanent_errors: [permanent_error])

          Relay.new(client: client, retry_policy: retry_policy, logger: Logger.new(File::NULL)).process_batch

          expect(DeadLetter.sole).to have_attributes(attempts: 1, error_class: "PermanentError")
        end

        specify "dead-letters a message whose event is gone, without retrying it" do
          client.subscribe_async(recording_handler("OrderReport"), to: [TestEvent])
          event = publish
          event_klass.where(event_id: event.event_id).delete_all

          result = build_relay.process_batch

          expect(result.dead).to eq(1)
          expect(DeadLetter.sole).to have_attributes(
            error_class: "RubyEventStore::OutboxRelay::Relay::MissingEvent",
            error_message: "event #{event.event_id} not found",
            attempts: 1,
          )
        end

        specify "dead-letters a message whose subscriber is not subscribed in the relay process" do
          client.subscribe_async(recording_handler("OrderReport"), to: [TestEvent])
          publish
          Message.update_all(subscriber: "Kernel")

          build_relay.process_batch

          expect(DeadLetter.sole).to have_attributes(
            subscriber: "Kernel",
            error_class: "RubyEventStore::OutboxRelay::Relay::UnknownSubscriber",
            error_message: "Kernel is not subscribed to TestEvent",
          )
        end

        specify "dead-letters a message whose event fails to deserialize, and delivers the rest of the batch" do
          handler = recording_handler("OrderReport")
          client.subscribe_async(handler, to: [TestEvent])
          first, corrupted, third = Array.new(3) { publish }
          event_klass.where(event_id: corrupted.event_id).update_all(data: "not: valid: yaml: [")

          result = build_relay.process_batch

          expect(result).to eq(Relay::BatchResult.new(claimed: 3, delivered: 2, retried: 0, dead: 1))
          expect(handler.received.map(&:event_id)).to eq([first.event_id, third.event_id])
          expect(DeadLetter.sole).to have_attributes(event_id: corrupted.event_id, error_class: "Psych::SyntaxError")
        end unless helper.json_data_type?

        specify "undeliverable messages at the head of the queue don't block the ones behind them" do
          handler = recording_handler("OrderReport")
          client.subscribe_async(handler, to: [TestEvent])
          poisoned = Array.new(3) { publish }
          healthy = publish
          event_klass.where(event_id: poisoned.map(&:event_id)).delete_all

          2.times { build_relay(batch_size: 2).process_batch }

          expect(handler.received.map(&:event_id)).to eq([healthy.event_id])
          expect(DeadLetter.count).to eq(3)
        end

        specify "a failing dispatch at the head of the queue doesn't block the messages behind it" do
          healthy = recording_handler("Healthy")
          client.subscribe_async(recording_handler("Failing") { |_event| raise "boom" }, to: [AnotherTestEvent])
          client.subscribe_async(healthy, to: [TestEvent])
          2.times { publish(AnotherTestEvent.new) }
          event = publish

          2.times { build_relay(batch_size: 2).process_batch }

          expect(healthy.received.map(&:event_id)).to eq([event.event_id])
        end

        specify "claims at most batch_size messages, oldest first" do
          handler = recording_handler("OrderReport")
          client.subscribe_async(handler, to: [TestEvent])
          events = Array.new(3) { publish }

          result = build_relay(batch_size: 2).process_batch

          expect(result.claimed).to eq(2)
          expect(handler.received.map(&:event_id)).to eq(events.first(2).map(&:event_id))
          expect(Message.pluck(:event_id)).to eq([events.last.event_id])
        end

        specify "a claimed message is hidden from other relays until its lease runs out" do
          client.subscribe_async(recording_handler("OrderReport"), to: [TestEvent])
          publish
          client.outbox.claim(10, now: now, lease_until: now + 60)

          expect(build_relay(clock: -> { now + 59 }).process_batch.claimed).to eq(0)
          expect(build_relay(clock: -> { now + 60 }).process_batch.delivered).to eq(1)
        end

        specify "delivers each message once, however many batches run" do
          handler = recording_handler("OrderReport")
          client.subscribe_async(handler, to: [TestEvent])
          publish

          3.times { build_relay.process_batch }

          expect(handler.received.size).to eq(1)
        end

        specify "delivers through the default ActiveJob scheduler" do
          TestAsyncJob.reset!
          client = helper.extended_client_class.new(repository: helper.repository)
          client.subscribe_async(TestAsyncJob, to: [TestEvent])
          event = TestEvent.new
          client.publish(event)

          Relay.new(client: client, logger: Logger.new(File::NULL)).process_batch

          expect(TestAsyncJob.received.map { |payload| payload.fetch("event_id") }).to eq([event.event_id])
        end
      end
    end
  end
end
