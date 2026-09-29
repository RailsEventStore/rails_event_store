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
      let(:notifications) { [] }
      let(:instrumentation) do
        notifications = self.notifications
        Object.new.tap do |instrumentation|
          instrumentation.define_singleton_method(:instrument) do |name, payload = {}, &block|
            notifications << [name, payload]
            block ? block.call(payload) : nil
          end
        end
      end

      def permanent_policy(*errors)
        RetryPolicy.new(max_attempts: 3, jitter: 0, permanent_errors: errors)
      end

      def build_relay(batch_size: 10, clock: self.clock, retry_policy: self.retry_policy)
        Relay.new(
          client: client,
          batch_size: batch_size,
          lease_duration: 60,
          retry_policy: retry_policy,
          clock: clock,
          instrumentation: instrumentation,
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

          expect(result).to eq(Relay::BatchResult.new(claimed: 1, delivered: 1, retried: 0, dead: 0, unrecorded: 0))
          expect(handler.received.map(&:event_id)).to eq([event.event_id])
          expect(Message.count).to eq(0)
        end

        describe "when the database fails while reading the events" do
          before do
            client.subscribe_async(recording_handler("OrderReport"), to: [TestEvent])
            2.times { publish }
          end

          specify "fails the batch instead of dead-lettering its messages, which stay for the next attempt" do
            specification = double(:specification)
            allow(specification).to receive(:events).and_raise(::ActiveRecord::ConnectionNotEstablished, "connection lost")
            allow(client).to receive(:read).and_return(specification)

            expect { build_relay.process_batch }.to raise_error(::ActiveRecord::ConnectionNotEstablished)

            expect(DeadLetter.count).to eq(0)
            expect(Message.pluck(:attempts)).to eq([0, 0])
          end

          specify "does so when it is the fallback read of a single event that fails" do
            specification = double(:specification)
            allow(specification).to receive(:events).and_raise("cannot be deserialized")
            allow(specification).to receive(:event).and_raise(::ActiveRecord::StatementInvalid, "timeout")
            allow(client).to receive(:read).and_return(specification)

            expect { build_relay.process_batch }.to raise_error(::ActiveRecord::StatementInvalid)

            expect(DeadLetter.count).to eq(0)
          end

          specify "stays a per-message matter for an error of the event itself, not of the database" do
            specification = double(:specification)
            allow(specification).to receive(:events).and_raise("cannot be deserialized")
            allow(specification).to receive(:event).and_raise("cannot be deserialized")
            allow(client).to receive(:read).and_return(specification)

            result = build_relay.process_batch

            expect(result.claimed).to eq(2)
            expect(result.retried + result.dead).to eq(2)
          end
        end

        describe "when recording what went wrong with a message fails" do
          let(:handler) do
            recording_handler("OrderReport") { |event| raise "boom" if event.event_id == @failing_id }
          end

          before do
            client.subscribe_async(handler, to: [TestEvent])
            @events = Array.new(3) { publish }
            @failing_id = @events[1].event_id
          end

          specify "still deletes the messages that were delivered, and leaves that one for after its lease" do
            allow(client.outbox).to receive(:reschedule).and_raise(::ActiveRecord::StatementInvalid, "deadlock")

            result = build_relay.process_batch

            expect(result).to eq(Relay::BatchResult.new(claimed: 3, delivered: 2, retried: 0, dead: 0, unrecorded: 1))
            expect(Message.sole.event_id).to eq(@events[1].event_id)
            expect(log.string).to include("Could not record the failure of outbox message #{Message.sole.id}: ActiveRecord::StatementInvalid")
          end

          specify "does the same when it is burying that fails" do
            allow(client.outbox).to receive(:bury).and_raise(::ActiveRecord::StatementInvalid, "deadlock")
            relay =
              Relay.new(
                client: client,
                batch_size: 10,
                retry_policy: RetryPolicy.new(max_attempts: 1),
                clock: clock,
                instrumentation: instrumentation,
                logger: Logger.new(log),
              )

            result = relay.process_batch

            expect(result.delivered).to eq(2)
            expect(result.unrecorded).to eq(1)
            expect(Message.count).to eq(1)
            expect(log.string).to include("Could not record the failure of outbox message")
          end

          specify "does the same for a message the relay could not resolve, recording its failure being what fails" do
            Message.where(event_id: @events[0].event_id).update_all(subscriber: "Kernel")
            allow(client.outbox).to receive(:reschedule).and_raise(::ActiveRecord::StatementInvalid, "deadlock")

            result = build_relay.process_batch

            expect(result).to eq(Relay::BatchResult.new(claimed: 3, delivered: 1, retried: 0, dead: 0, unrecorded: 2))
            expect(Message.pluck(:event_id)).to contain_exactly(@events[0].event_id, @events[1].event_id)
            expect(log.string).to include("Could not record the failure of outbox message #{Message.find_by!(event_id: @events[0].event_id).id}:")
          end

          specify "never puts the error's message in the log" do
            allow(client.outbox).to receive(:reschedule).and_raise(::ActiveRecord::StatementInvalid, "password=hunter2")

            build_relay.process_batch

            expect(log.string).not_to include("hunter2")
          end
        end

        specify "dead-letters a failure of an anonymous error class, which has no name" do
          anonymous = Class.new(StandardError)
          client.subscribe_async(recording_handler("Failing") { |_event| raise anonymous, "boom" }, to: [TestEvent])
          publish
          relay =
            Relay.new(client: client, retry_policy: RetryPolicy.new(max_attempts: 1), clock: clock, logger: Logger.new(log))

          result = relay.process_batch

          expect(result.dead).to eq(1)
          expect(DeadLetter.sole.error_class).to eq(anonymous.to_s)
          expect(DeadLetter.sole.error_class).to start_with("#<Class:")
        end

        specify "instruments the batch, with what happened to its messages" do
          client.subscribe_async(recording_handler("OrderReport"), to: [TestEvent])
          2.times { publish }

          build_relay.process_batch

          expect(notifications).to eq(
            [["process_batch.outbox_relay.ruby_event_store", { claimed: 2, delivered: 2, retried: 0, dead: 0, unrecorded: 0 }]],
          )
        end

        specify "instruments a retried message, without the error's message" do
          client.subscribe_async(recording_handler("Failing") { |_event| raise ArgumentError, "password=hunter2" }, to: [TestEvent])
          event = publish

          build_relay.process_batch

          failure = notifications.find { |name, _| name == "message_failed.outbox_relay.ruby_event_store" }
          expect(failure.last).to eq(
            outbox_id: Message.sole.id,
            event_id: event.event_id,
            topic: "TestEvent",
            subscriber: "Failing",
            attempts: 1,
            error_class: "ArgumentError",
            outcome: :retried,
          )
          expect(failure.last.values.grep(String).join).not_to include("hunter2")
        end

        specify "instruments a message whose subscriber is unknown as retried, like any other failure" do
          client.subscribe_async(recording_handler("OrderReport"), to: [TestEvent])
          event = publish
          Message.update_all(subscriber: "Kernel")

          build_relay.process_batch

          failure = notifications.find { |name, _| name == "message_failed.outbox_relay.ruby_event_store" }
          expect(failure.last).to include(
            event_id: event.event_id,
            subscriber: "Kernel",
            attempts: 1,
            error_class: "RubyEventStore::OutboxRelay::Relay::UnknownSubscriber",
            outcome: :retried,
          )
        end

        specify "instruments a dead-lettered message" do
          client.subscribe_async(recording_handler("OrderReport"), to: [TestEvent])
          event = publish
          Message.update_all(subscriber: "Kernel")

          build_relay(retry_policy: permanent_policy(Relay::UnknownSubscriber)).process_batch

          failure = notifications.find { |name, _| name == "message_failed.outbox_relay.ruby_event_store" }
          expect(failure.last).to include(
            event_id: event.event_id,
            subscriber: "Kernel",
            attempts: 1,
            error_class: "RubyEventStore::OutboxRelay::Relay::UnknownSubscriber",
            outcome: :dead,
          )
        end

        specify "instruments nothing, and logs nothing, for a message that another relay already delivered" do
          client.subscribe_async(recording_handler("OrderReport"), to: [TestEvent])
          publish
          Message.update_all(subscriber: "Kernel")
          allow(client.outbox).to receive(:bury).and_return(false)

          result = build_relay(retry_policy: permanent_policy(Relay::UnknownSubscriber)).process_batch

          expect(result.dead).to eq(1)
          expect(notifications.map(&:first)).to eq(["process_batch.outbox_relay.ruby_event_store"])
          expect(log.string).not_to include("moved to dead letters")
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

          expect(result).to eq(Relay::BatchResult.new(claimed: 1, delivered: 0, retried: 1, dead: 0, unrecorded: 0))
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

        describe "a message whose event is gone" do
          let(:event) { publish }

          before do
            client.subscribe_async(recording_handler("OrderReport"), to: [TestEvent])
            event_klass.where(event_id: event.event_id).delete_all
          end

          specify "is retried, as the event may only be late to a replica" do
            result = build_relay.process_batch

            expect(result).to eq(Relay::BatchResult.new(claimed: 1, delivered: 0, retried: 1, dead: 0, unrecorded: 0))
            expect(Message.sole).to have_attributes(
              attempts: 1,
              last_error: "RubyEventStore::OutboxRelay::Relay::MissingEvent: event #{event.event_id} not found",
            )
            expect(DeadLetter.count).to eq(0)
          end

          specify "is dead-lettered at once when the retry policy calls the error permanent" do
            result = build_relay(retry_policy: permanent_policy(Relay::MissingEvent)).process_batch

            expect(result.dead).to eq(1)
            expect(DeadLetter.sole).to have_attributes(
              error_class: "RubyEventStore::OutboxRelay::Relay::MissingEvent",
              error_message: "event #{event.event_id} not found",
              attempts: 1,
            )
          end
        end

        describe "a message whose subscriber is not subscribed in the relay process" do
          before do
            client.subscribe_async(recording_handler("OrderReport"), to: [TestEvent])
            publish
            Message.update_all(subscriber: "Kernel")
          end

          specify "is retried, as a deploy adding the subscriber may not have reached the relay yet" do
            result = build_relay.process_batch

            expect(result).to eq(Relay::BatchResult.new(claimed: 1, delivered: 0, retried: 1, dead: 0, unrecorded: 0))
            expect(Message.sole).to have_attributes(
              attempts: 1,
              last_error: "RubyEventStore::OutboxRelay::Relay::UnknownSubscriber: Kernel is not subscribed to TestEvent",
            )
          end

          specify "is delivered once the relay knows the subscriber" do
            Message.update_all(subscriber: "LateSubscriber")
            build_relay.process_batch
            handler = recording_handler("LateSubscriber")
            client.subscribe_async(handler, to: [TestEvent])
            Message.update_all(next_attempt_at: now)

            result = build_relay.process_batch

            expect(result.delivered).to eq(1)
            expect(handler.received.size).to eq(1)
            expect(Message.count).to eq(0)
          end

          specify "is dead-lettered at once when the retry policy calls the error permanent" do
            build_relay(retry_policy: permanent_policy(Relay::UnknownSubscriber)).process_batch

            expect(DeadLetter.sole).to have_attributes(
              subscriber: "Kernel",
              error_class: "RubyEventStore::OutboxRelay::Relay::UnknownSubscriber",
              error_message: "Kernel is not subscribed to TestEvent",
            )
          end
        end

        describe "a message whose event fails to deserialize" do
          let(:handler) { recording_handler("OrderReport") }

          before do
            client.subscribe_async(handler, to: [TestEvent])
            @first, @corrupted, @third = Array.new(3) { publish }
            event_klass.where(event_id: @corrupted.event_id).update_all(data: "not: valid: yaml: [")
          end

          specify "is retried, and the rest of the batch is delivered" do
            result = build_relay.process_batch

            expect(result).to eq(Relay::BatchResult.new(claimed: 3, delivered: 2, retried: 1, dead: 0, unrecorded: 0))
            expect(handler.received.map(&:event_id)).to eq([@first.event_id, @third.event_id])
            expect(Message.sole).to have_attributes(event_id: @corrupted.event_id, attempts: 1)
            expect(Message.sole.last_error).to start_with("Psych::SyntaxError")
          end

          specify "is dead-lettered at once when the retry policy calls the error permanent" do
            result = build_relay(retry_policy: permanent_policy(Psych::SyntaxError)).process_batch

            expect(result).to eq(Relay::BatchResult.new(claimed: 3, delivered: 2, retried: 0, dead: 1, unrecorded: 0))
            expect(DeadLetter.sole).to have_attributes(event_id: @corrupted.event_id, error_class: "Psych::SyntaxError")
          end
        end unless helper.json_data_type?

        specify "undeliverable messages at the head of the queue don't block the ones behind them" do
          handler = recording_handler("OrderReport")
          client.subscribe_async(handler, to: [TestEvent])
          poisoned = Array.new(3) { publish }
          healthy = publish
          event_klass.where(event_id: poisoned.map(&:event_id)).delete_all

          2.times { build_relay(batch_size: 2).process_batch }

          expect(handler.received.map(&:event_id)).to eq([healthy.event_id])
          expect(DeadLetter.count).to eq(0)
          expect(Message.pluck(:attempts)).to eq([1, 1, 1])
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

        specify "delivers one by one, without a bulk call, through a dispatcher that can't deliver batches" do
          client.subscribe_async(recording_handler("OrderReport"), to: [TestEvent])
          publish
          allow(client.async_subscriptions).to receive(:dispatch_all).and_call_original
          allow(client.async_subscriptions).to receive(:dispatch).and_call_original

          build_relay.process_batch

          expect(client.async_subscriptions).not_to have_received(:dispatch_all)
          expect(client.async_subscriptions).to have_received(:dispatch).once
        end

        describe "with a dispatcher that delivers whole batches" do
          let(:bulk_calls) { [] }
          let(:single_calls) { [] }
          let(:bulk_results) { ->(deliveries) { Array.new(deliveries.size) } }
          let(:bulk_raises) { false }
          let(:dispatcher) do
            bulk_calls = self.bulk_calls
            single_calls = self.single_calls
            results = bulk_results
            raises = bulk_raises
            Object.new.tap do |dispatcher|
              dispatcher.define_singleton_method(:verify) { |_subscriber| true }
              dispatcher.define_singleton_method(:call) do |subscriber, event, _record|
                single_calls << [subscriber, event.event_id]
                subscriber.call(event)
              end
              dispatcher.define_singleton_method(:call_all) do |deliveries|
                bulk_calls << deliveries
                raise "bulk down" if raises
                results.call(deliveries)
              end
            end
          end
          let(:client) do
            helper.extended_client_class.new(
              repository: helper.repository,
              async_subscriptions: AsyncSubscriptions.new(dispatcher: dispatcher),
            )
          end

          specify "hands the whole batch over in one call, with each message's subscriber, event and record" do
            handler = recording_handler("OrderReport")
            client.subscribe_async(handler, to: [TestEvent])
            events = Array.new(3) { publish }

            result = build_relay.process_batch

            expect(result).to eq(Relay::BatchResult.new(claimed: 3, delivered: 3, retried: 0, dead: 0, unrecorded: 0))
            expect(bulk_calls.size).to eq(1)
            expect(bulk_calls.first.map(&:subscriber)).to eq([handler] * 3)
            expect(bulk_calls.first.map { |delivery| delivery.event.event_id }).to eq(events.map(&:event_id))
            expect(bulk_calls.first.map { |delivery| delivery.record.event_id }).to eq(events.map(&:event_id))
            expect(bulk_calls.first).to all(be_an_instance_of(AsyncSubscriptions::Delivery))
            expect(single_calls).to be_empty
            expect(Message.count).to eq(0)
          end

          context "when it reports a failure for some deliveries" do
            let(:bulk_results) { ->(_deliveries) { [nil, RuntimeError.new("nope"), nil] } }

            specify "retries only those messages" do
              client.subscribe_async(recording_handler("OrderReport"), to: [TestEvent])
              events = Array.new(3) { publish }

              result = build_relay.process_batch

              expect(result).to eq(Relay::BatchResult.new(claimed: 3, delivered: 2, retried: 1, dead: 0, unrecorded: 0))
              message = Message.sole
              expect(message).to have_attributes(event_id: events[1].event_id, attempts: 1, last_error: "RuntimeError: nope")
            end
          end

          context "when it fails as a whole" do
            let(:bulk_raises) { true }

            specify "falls back to delivering one by one, isolating each failure" do
              handler = recording_handler("OrderReport") { |event| raise "boom" if event.event_id == @failing_id }
              client.subscribe_async(handler, to: [TestEvent])
              events = Array.new(3) { publish }
              @failing_id = events[1].event_id

              result = build_relay.process_batch

              expect(result).to eq(Relay::BatchResult.new(claimed: 3, delivered: 2, retried: 1, dead: 0, unrecorded: 0))
              expect(single_calls.map(&:last)).to eq(events.map(&:event_id))
              expect(Message.sole.event_id).to eq(events[1].event_id)
            end

            specify "still reproduces correlation_id and causation_id around each single delivery" do
              observed = []
              handler = recording_handler("OrderReport") { |_event| observed << client.metadata.slice(:correlation_id, :causation_id) }
              client.subscribe_async(handler, to: [TestEvent])
              event = publish

              build_relay.process_batch

              expect(observed).to eq([{ correlation_id: event.metadata[:correlation_id], causation_id: event.event_id }])
            end
          end

          specify "hands over only the messages that could be resolved" do
            handler = recording_handler("OrderReport")
            client.subscribe_async(handler, to: [TestEvent])
            resolvable, unresolvable = publish, publish
            Message.where(event_id: unresolvable.event_id).update_all(subscriber: "Kernel")

            result = build_relay.process_batch

            expect(result).to eq(Relay::BatchResult.new(claimed: 2, delivered: 1, retried: 1, dead: 0, unrecorded: 0))
            expect(bulk_calls.sole.map { |delivery| delivery.event.event_id }).to eq([resolvable.event_id])
          end

          specify "isn't called at all when no message could be resolved" do
            client.subscribe_async(recording_handler("OrderReport"), to: [TestEvent])
            publish
            Message.update_all(subscriber: "Kernel")

            result = build_relay.process_batch

            expect(result.retried).to eq(1)
            expect(bulk_calls).to be_empty
          end
        end

        specify "enqueues a batch through the default dispatcher with one ActiveJob.perform_all_later" do
          job = stub_const("BatchedJob", Class.new(ActiveJob::Base) { def perform(payload) = nil })
          job.queue_adapter = :test
          client = helper.extended_client_class.new(repository: helper.repository)
          client.subscribe_async(job, to: [TestEvent])
          events = Array.new(3) { TestEvent.new }.each { |event| client.publish(event) }
          allow(ActiveJob).to receive(:perform_all_later).and_call_original

          result = Relay.new(client: client, logger: Logger.new(File::NULL)).process_batch

          expect(result.delivered).to eq(3)
          expect(ActiveJob).to have_received(:perform_all_later).once
          expect(job.queue_adapter.enqueued_jobs.map { |enqueued| enqueued.fetch(:args).first.fetch("event_id") }).to eq(events.map(&:event_id))
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
