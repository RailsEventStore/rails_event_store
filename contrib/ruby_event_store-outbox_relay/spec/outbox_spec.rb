# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe Outbox do
      helper = SpecHelper.new

      around { |example| helper.run_lifecycle { example.run } }

      let(:outbox) { Outbox.new }
      let(:now) { Time.utc(2026, 9, 29, 12, 0, 0) }
      let(:subscriptions) { helper.sync_subscriptions }

      def entry_for(message)
        Outbox::Entry.new(
          outbox_id: message.id,
          event_id: message.event_id,
          topic: message.topic,
          subscriber: message.subscriber,
          attempts: message.attempts,
          created_at: message.created_at,
        )
      end

      def record(event_type: "TestEvent")
        RubyEventStore::Record.new(
          event_id: SecureRandom.uuid,
          data: {},
          metadata: {},
          event_type: event_type,
          timestamp: now,
          valid_at: now,
        )
      end

      def add_messages(*records)
        outbox.append(records, topics: records.map(&:event_type), subscriptions: subscriptions, now: now) { :appended }
      end

      describe "#append" do
        specify "inserts one message per async subscriber of each record's event type, due now" do
          subscriptions.add(recording_handler("First"), ["TestEvent"])
          subscriptions.add(recording_handler("Second"), ["TestEvent"])
          subscriptions.add(recording_handler("Other"), ["OtherEvent"])
          test_event, other_event = record, record(event_type: "OtherEvent")

          add_messages(test_event, other_event)

          expect(Message.order(:id).map { |m| [m.event_id, m.topic, m.subscriber, m.attempts, m.next_attempt_at, m.created_at] }).to eq(
            [
              [test_event.event_id, "TestEvent", "First", 0, now, now],
              [test_event.event_id, "TestEvent", "Second", 0, now, now],
              [other_event.event_id, "OtherEvent", "Other", 0, now, now],
            ],
          )
        end

        specify "uses the topic given for each record, whatever the record's own event type" do
          subscriptions.add(recording_handler("TopicHandler"), ["custom.topic"])
          subscriptions.add(recording_handler("OtherHandler"), ["other.topic"])
          subscriptions.add(recording_handler("TypeHandler"), ["TestEvent"])
          first, second = record, record

          outbox.append([first, second], topics: %w[custom.topic other.topic], subscriptions: subscriptions, now: now) {}

          expect(Message.order(:id).pluck(:event_id, :topic, :subscriber)).to eq(
            [[first.event_id, "custom.topic", "TopicHandler"], [second.event_id, "other.topic", "OtherHandler"]],
          )
        end

        specify "inserts the messages without asking for their ids, so INSERT is all the role needs" do
          subscriptions.add(recording_handler("First"), ["TestEvent"])
          allow(Message).to receive(:insert_all!).and_call_original

          add_messages(record)

          expect(Message).to have_received(:insert_all!).with(an_instance_of(Array), returning: false)
        end

        specify "returns the block's result" do
          subscriptions.add(recording_handler("First"), ["TestEvent"])

          expect(add_messages(record)).to eq(:appended)
        end

        specify "runs the block without a transaction and inserts nothing when no record has async subscribers" do
          transaction_open = nil

          result = outbox.append([record], topics: ["TestEvent"], subscriptions: subscriptions, now: now) do
            transaction_open = Message.connection.transaction_open?
            :appended
          end

          expect(result).to eq(:appended)
          expect(transaction_open).to eq(false)
          expect(Message.count).to eq(0)
        end

        specify "runs the block and the insert in one transaction, so a failing insert rolls back the block's writes" do
          subscriptions.add(recording_handler("First"), ["TestEvent"])
          allow(Message).to receive(:insert_all!).and_raise(::ActiveRecord::StatementInvalid, "boom")

          expect do
            outbox.append([record], topics: ["TestEvent"], subscriptions: subscriptions, now: now) do
              DeadLetter.insert!(
                {
                  event_id: SecureRandom.uuid,
                  topic: "t",
                  subscriber: "s",
                  attempts: 1,
                  error_class: "E",
                  first_enqueued_at: now,
                  dead_at: now,
                },
              )
            end
          end.to raise_error(::ActiveRecord::StatementInvalid)
          expect(DeadLetter.count).to eq(0)
        end

        specify "nests as a savepoint inside an already open transaction" do
          subscriptions.add(recording_handler("First"), ["TestEvent"])

          Message.transaction do
            add_messages(record)
            raise ::ActiveRecord::Rollback
          end

          expect(Message.count).to eq(0)
        end
      end

      describe "#claim" do
        before { subscriptions.add(recording_handler("First"), ["TestEvent"]) }

        specify "returns due messages oldest first, at most batch_size, and leases them" do
          records = Array.new(3) { record }
          add_messages(*records)

          claimed = outbox.claim(2, now: now, lease_until: now + 60)

          expect(claimed.map(&:event_id)).to eq(records.first(2).map(&:event_id))
          expect(Message.order(:id).pluck(:next_attempt_at)).to eq([now + 60, now + 60, now])
        end

        specify "orders by next_attempt_at before id" do
          first, second = record, record
          add_messages(first, second)
          Message.where(event_id: first.event_id).update_all(next_attempt_at: now - 1)
          Message.where(event_id: second.event_id).update_all(next_attempt_at: now - 2)

          expect(outbox.claim(10, now: now, lease_until: now + 60).map(&:event_id)).to eq([second.event_id, first.event_id])
        end

        specify "skips messages not yet due" do
          add_messages(record)

          expect(outbox.claim(10, now: now - 1, lease_until: now + 60)).to eq([])
          expect(Message.sole.next_attempt_at).to eq(now)
        end

        specify "runs inside a transaction, as a savepoint" do
          allow(Message).to receive(:transaction).and_call_original

          outbox.claim(10, now: now, lease_until: now + 60)

          expect(Message).to have_received(:transaction).with(requires_new: true).at_least(:once)
        end

        specify "issues no UPDATE when nothing is due" do
          statements = []
          subscriber =
            ::ActiveSupport::Notifications.subscribe("sql.active_record") { |*, payload| statements << payload[:sql] }

          outbox.claim(10, now: now, lease_until: now + 60)

          expect(statements.grep(/\AUPDATE/)).to eq([])
        ensure
          ::ActiveSupport::Notifications.unsubscribe(subscriber)
        end

        specify "returns detached entries carrying the columns the relay needs" do
          record = record()
          add_messages(record)

          entry = outbox.claim(10, now: now, lease_until: now + 60).sole

          expect(entry).to be_an_instance_of(Outbox::Entry)
          expect(entry).to have_attributes(
            outbox_id: Message.sole.id,
            event_id: record.event_id,
            topic: "TestEvent",
            subscriber: "First",
            attempts: 0,
            created_at: now,
          )
        end

        specify "skips messages locked by another relay's claim" do
          locked, free = record, record
          add_messages(locked, free)
          locking = Queue.new
          release = Queue.new
          holder =
            Thread.new do
              Message.transaction do
                Message.where(event_id: locked.event_id).lock.load
                locking << true
                release.pop
              end
            end
          locking.pop

          claimed = outbox.claim(10, now: now, lease_until: now + 60)

          release << true
          holder.join
          expect(claimed.map(&:event_id)).to eq([free.event_id])
        end if helper.postgres? || helper.mysql?
      end

      describe "with models of its own, for an event store on another connection" do
        let(:message_klass) { Class.new(::ActiveRecord::Base) { self.table_name = "event_store_outbox_messages" } }
        let(:dead_letter_klass) { Class.new(::ActiveRecord::Base) { self.table_name = "event_store_outbox_dead_letters" } }
        let(:custom) { Outbox.new(message_klass: message_klass, dead_letter_klass: dead_letter_klass) }

        before { subscriptions.add(recording_handler("First"), ["TestEvent"]) }

        specify "opens the transaction of the events on the connection of its own models, and writes through them" do
          allow(message_klass).to receive(:transaction).and_call_original
          allow(Message).to receive(:transaction).and_call_original

          custom.append([record], topics: ["TestEvent"], subscriptions: subscriptions, now: now) { :appended }

          expect(message_klass).to have_received(:transaction).with(requires_new: true)
          expect(Message).not_to have_received(:transaction)
          expect(message_klass.count).to eq(1)
        end

        specify "claims, and moves to the dead letters, through them as well" do
          custom.append([record], topics: ["TestEvent"], subscriptions: subscriptions, now: now) {}

          entry = custom.claim(10, now: now, lease_until: now + 60).sole
          custom.bury(entry, attempts: 1, error: RuntimeError.new("boom"), now: now)

          expect(message_klass.count).to eq(0)
          expect(dead_letter_klass.sole.event_id).to eq(entry.event_id)
          expect(Message.count).to eq(0)
          expect(DeadLetter.count).to eq(1)
        end
      end

      describe "#stats" do
        before { subscriptions.add(recording_handler("First"), ["TestEvent"]) }

        specify "counts the due messages and the dead letters, and dates the oldest due message" do
          add_messages(record, record, record)
          ids = Message.order(:id).pluck(:id)
          Message.where(id: ids[0]).update_all(next_attempt_at: now - 30)
          Message.where(id: ids[1]).update_all(next_attempt_at: now - 10)
          Message.where(id: ids[2]).update_all(next_attempt_at: now + 60)
          2.times { DeadLetter.create!(event_id: SecureRandom.uuid, topic: "t", subscriber: "s", attempts: 1, error_class: "E", first_enqueued_at: now, dead_at: now) }

          stats = outbox.stats(now: now)

          expect(stats).to eq(Outbox::Stats.new(backlog: 2, oldest_due_age: 30.0, dead_letters: 2))
        end

        specify "has no age when nothing is due" do
          add_messages(record)
          Message.update_all(next_attempt_at: now + 60)

          expect(outbox.stats(now: now)).to eq(Outbox::Stats.new(backlog: 0, oldest_due_age: nil, dead_letters: 0))
        end

        specify "counts in the database, without loading the messages" do
          add_messages(record)
          Message.first
          DeadLetter.first
          statements = []
          subscriber =
            ::ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
              statements << payload[:sql] unless payload[:name] == "SCHEMA"
            end

          outbox.stats(now: now)

          expect(statements).not_to be_empty
          expect(statements).to all(match(/\ASELECT (COUNT|MIN)/))
        ensure
          ::ActiveSupport::Notifications.unsubscribe(subscriber)
        end

        specify "counts up to STATS_LIMIT, so a huge backlog stays cheap to measure" do
          stub_const("#{Outbox}::STATS_LIMIT", 2)
          add_messages(record, record, record)
          3.times { DeadLetter.create!(event_id: SecureRandom.uuid, topic: "t", subscriber: "s", attempts: 1, error_class: "E", first_enqueued_at: now, dead_at: now) }

          stats = outbox.stats(now: now)

          expect(stats.backlog).to eq(2)
          expect(stats.dead_letters).to eq(2)
        end

        specify "doesn't count the messages being delivered, which are leased" do
          add_messages(record, record)
          outbox.claim(1, now: now, lease_until: now + 60)

          expect(outbox.stats(now: now).backlog).to eq(1)
        end
      end

      describe "#due (private)" do
        specify "selects the relay's columns of messages due by now, oldest first, and locks them skipping other relays' locks" do
          calls = []
          relation = double(:relation)
          %i[select where order limit lock].each do |name|
            allow(relation).to receive(name) do |*args|
              calls << [name, args]
              relation
            end
          end
          message_klass = relation
          outbox = Outbox.new(message_klass: message_klass)

          result = outbox.send(:due, 25, now)

          expect(result).to equal(relation)
          expect(calls).to eq(
            [
              [:select, %i[id event_id topic subscriber attempts created_at]],
              [:where, [{ next_attempt_at: ..now }]],
              [:order, %i[next_attempt_at id]],
              [:limit, [25]],
              [:lock, ["FOR UPDATE SKIP LOCKED"]],
            ],
          )
        end
      end

      describe "#transaction (private)" do
        specify "opens a savepoint when a transaction is already open" do
          allow(Message).to receive(:transaction).and_call_original

          outbox.send(:transaction) {}

          expect(Message).to have_received(:transaction).with(requires_new: true)
        end
      end

      describe "#delete" do
        specify "removes the given messages only" do
          subscriptions.add(recording_handler("First"), ["TestEvent"])
          add_messages(record, record)
          first, second = Message.order(:id).to_a

          outbox.delete([first.id])

          expect(Message.pluck(:id)).to eq([second.id])
        end

        specify "does nothing for no ids" do
          expect(Message).not_to receive(:where)

          outbox.delete([])
        end
      end

      describe "#reschedule" do
        specify "records the attempt, the next attempt time, and a truncated error summary" do
          subscriptions.add(recording_handler("First"), ["TestEvent"])
          add_messages(record)

          outbox.reschedule(entry_for(Message.sole), attempts: 2, next_attempt_at: now + 30, error: RuntimeError.new("x" * 2000))

          message = Message.sole
          expect(message.attempts).to eq(2)
          expect(message.next_attempt_at).to eq(now + 30)
          expect(message.last_error).to eq("RuntimeError: #{"x" * 986}")
        end

        specify "summarizes the error by its class and message, not its string form" do
          error_class =
            Class.new(StandardError) do
              def message = "custom message"
              def to_s = "not this one"
            end
          stub_const("SummaryError", error_class)
          subscriptions.add(recording_handler("First"), ["TestEvent"])
          add_messages(record)

          outbox.reschedule(entry_for(Message.sole), attempts: 1, next_attempt_at: now, error: error_class.new)

          expect(Message.sole.last_error).to eq("SummaryError: custom message")
        end

        specify "changes only the given message, which is identified by its id" do
          subscriptions.add(recording_handler("First"), ["TestEvent"])
          add_messages(record, record)
          first, second = Message.order(:id).to_a

          outbox.reschedule(entry_for(first), attempts: 5, next_attempt_at: now + 30, error: RuntimeError.new("boom"))

          expect(first.reload.attempts).to eq(5)
          expect(second.reload.attempts).to eq(0)
        end
      end

      describe "#bury" do
        let(:error) do
          RuntimeError.new("y" * 2000).tap { |e| e.set_backtrace(Array.new(30) { |i| "line #{i}" }) }
        end

        before do
          subscriptions.add(recording_handler("First"), ["TestEvent"])
          add_messages(record, record)
        end

        specify "moves the message to the dead letters with the error details" do
          message = Message.order(:id).first

          moved = outbox.bury(entry_for(message), attempts: 4, error: error, now: now + 5)

          expect(moved).to eq(true)
          expect(Message.count).to eq(1)
          expect(DeadLetter.sole).to have_attributes(
            event_id: message.event_id,
            topic: "TestEvent",
            subscriber: "First",
            attempts: 4,
            error_class: "RuntimeError",
            error_message: "y" * 1000,
            backtrace: Array.new(20) { |i| "line #{i}" }.join("\n"),
            first_enqueued_at: now,
            dead_at: now + 5,
          )
        end

        specify "stores an empty backtrace for an error that was never raised" do
          outbox.bury(entry_for(Message.order(:id).first), attempts: 1, error: RuntimeError.new("boom"), now: now)

          expect(DeadLetter.sole.backtrace).to eq("")
        end

        specify "moves only the given message, which is identified by its id" do
          first, second = Message.order(:id).to_a

          moved = outbox.bury(entry_for(first), attempts: 1, error: error, now: now)

          expect(moved).to eq(true)
          expect(Message.pluck(:id)).to eq([second.id])
          expect(DeadLetter.sole.event_id).to eq(first.event_id)
        end

        specify "records the error's class name and message, not its string form" do
          error_class =
            Class.new(StandardError) do
              def message = "custom message"
              def to_s = "not this one"
            end
          stub_const("BuryError", error_class)
          allow(DeadLetter).to receive(:insert!).and_call_original

          outbox.bury(entry_for(Message.order(:id).first), attempts: 2, error: error_class.new, now: now)

          expect(DeadLetter).to have_received(:insert!).with(
            hash_including(error_class: "BuryError", error_message: "custom message", attempts: 2),
            returning: false,
          )
        end

        specify "runs inside a savepoint" do
          allow(Message).to receive(:transaction).and_call_original

          outbox.bury(entry_for(Message.order(:id).first), attempts: 1, error: error, now: now)

          expect(Message).to have_received(:transaction).with(requires_new: true)
        end

        specify "does nothing when the message is already gone" do
          message = entry_for(Message.order(:id).first)
          Message.delete_all

          moved = outbox.bury(message, attempts: 1, error: error, now: now)

          expect(moved).to eq(false)
          expect(DeadLetter.count).to eq(0)
        end
      end
    end
  end
end
