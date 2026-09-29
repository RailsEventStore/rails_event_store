# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe DeadLetters do
      helper = SpecHelper.new

      around { |example| helper.run_lifecycle { example.run } }

      let(:now) { Time.utc(2026, 9, 29, 12, 0, 0) }
      let(:dead_letters) { DeadLetters.new(clock: -> { now }) }

      def dead_letter(topic: "TestEvent", subscriber: "OrderReport")
        DeadLetter.create!(
          event_id: SecureRandom.uuid,
          topic: topic,
          subscriber: subscriber,
          attempts: 25,
          error_class: "RuntimeError",
          error_message: "boom",
          backtrace: "",
          first_enqueued_at: now - 3600,
          dead_at: now - 60,
        )
      end

      def message_attributes
        Message.order(:id).map { |m| [m.event_id, m.topic, m.subscriber, m.attempts, m.next_attempt_at, m.created_at] }
      end

      specify "enumerates dead letters oldest first" do
        first, second = dead_letter, dead_letter

        expect(dead_letters.map(&:id)).to eq([first.id, second.id])
        expect(dead_letters.each).to be_a(Enumerator)
      end

      specify "yields every dead letter to the given block" do
        first = dead_letter
        yielded = []

        dead_letters.each { |dead_letter| yielded << dead_letter.id }

        expect(yielded).to eq([first.id])
      end

      specify "counts in the database, without loading dead letters" do
        allow(DeadLetter).to receive(:count).and_return(42)

        expect(dead_letters.count).to eq(42)
      end

      describe "#requeue" do
        specify "moves the dead letter back to the outbox as a fresh message, due now" do
          requeued, kept = dead_letter, dead_letter

          dead_letters.requeue(requeued.id)

          expect(message_attributes).to eq([[requeued.event_id, "TestEvent", "OrderReport", 0, now, now]])
          expect(DeadLetter.pluck(:id)).to eq([kept.id])
        end

        specify "raises for an unknown id, changing nothing" do
          kept = dead_letter

          expect { dead_letters.requeue(kept.id + 1) }.to raise_error(::ActiveRecord::RecordNotFound) { |error|
            expect(error.message).to eq("Couldn't find dead letter with id=#{kept.id + 1}")
            expect(error.model).to eq("RubyEventStore::OutboxRelay::DeadLetter")
            expect(error.primary_key).to eq("id")
            expect(error.id).to eq(kept.id + 1)
          }
          expect(Message.count).to eq(0)
          expect(DeadLetter.count).to eq(1)
        end

        specify "rolls back the removal when the message can't be inserted" do
          kept = dead_letter
          allow(Message).to receive(:insert_all!).and_raise(::ActiveRecord::StatementInvalid, "boom")

          expect { dead_letters.requeue(kept.id) }.to raise_error(::ActiveRecord::StatementInvalid)
          expect(DeadLetter.pluck(:id)).to eq([kept.id])
        end
      end

      describe "#requeue_all" do
        specify "moves every dead letter back, in batches, returning how many" do
          stub_const("#{DeadLetters}::BATCH_SIZE", 2)
          all = Array.new(3) { dead_letter }

          count = dead_letters.requeue_all

          expect(count).to eq(3)
          expect(Message.order(:id).pluck(:event_id)).to eq(all.map(&:event_id))
          expect(DeadLetter.count).to eq(0)
        end

        specify "narrows by topic and subscriber" do
          matching = dead_letter(topic: "A", subscriber: "X")
          dead_letter(topic: "A", subscriber: "Y")
          dead_letter(topic: "B", subscriber: "X")

          count = dead_letters.requeue_all(topic: "A", subscriber: "X")

          expect(count).to eq(1)
          expect(Message.pluck(:event_id)).to eq([matching.event_id])
          expect(DeadLetter.count).to eq(2)
        end

        specify "narrows by topic alone" do
          dead_letter(topic: "A", subscriber: "X")
          dead_letter(topic: "A", subscriber: "Y")
          dead_letter(topic: "B", subscriber: "X")

          expect(dead_letters.requeue_all(topic: "A")).to eq(2)
        end

        specify "narrows by subscriber alone" do
          dead_letter(topic: "A", subscriber: "X")
          dead_letter(topic: "A", subscriber: "Y")
          dead_letter(topic: "B", subscriber: "X")

          expect(dead_letters.requeue_all(subscriber: "X")).to eq(2)
        end

        specify "returns 0 when there is nothing to requeue" do
          expect(dead_letters.requeue_all).to eq(0)
        end

        specify "moves at most BATCH_SIZE of the oldest dead letters at a time" do
          stub_const("#{DeadLetters}::BATCH_SIZE", 2)
          3.times { dead_letter }
          scopes = []
          allow(dead_letters).to receive(:move).and_wrap_original do |original, scope|
            scopes << scope.to_sql
            original.call(scope)
          end

          dead_letters.requeue_all

          expect(scopes.size).to eq(3)
          expect(scopes.uniq.sole).to end_with('ORDER BY "event_store_outbox_dead_letters"."id" ASC LIMIT 2')
        end
      end

      describe "#discard" do
        specify "deletes the dead letter" do
          discarded, kept = dead_letter, dead_letter

          dead_letters.discard(discarded.id)

          expect(DeadLetter.pluck(:id)).to eq([kept.id])
          expect(Message.count).to eq(0)
        end

        specify "raises for an unknown id" do
          expect { dead_letters.discard(42) }.to raise_error(::ActiveRecord::RecordNotFound, "Couldn't find dead letter with id=42")
        end
      end

      describe "#move (private)" do
        specify "locks the dead letters, requeues them and deletes exactly that scope, in a savepoint" do
          scope = double(:scope)
          locked = double(:locked)
          allow(scope).to receive(:lock).and_return(locked)
          allow(locked).to receive(:pluck).with(:event_id, :topic, :subscriber).and_return([["e-1", "T", "S"]])
          allow(scope).to receive(:delete_all).and_return(1)
          allow(Message).to receive(:insert_all!)
          allow(DeadLetter).to receive(:transaction).and_yield

          moved = dead_letters.send(:move, scope)

          expect(moved).to eq(1)
          expect(DeadLetter).to have_received(:transaction).with(requires_new: true)
          expect(Message).to have_received(:insert_all!).with(
            [{ event_id: "e-1", topic: "T", subscriber: "S", next_attempt_at: now, created_at: now }],
          )
        end
      end

      specify "defaults to the current UTC time" do
        requeued = dead_letter

        DeadLetters.new.requeue(requeued.id)

        expect(Message.sole.next_attempt_at).to be_within(5).of(Time.now.utc)
        expect(DeadLetters.new.instance_variable_get(:@clock).call).to be_utc
      end
    end
  end
end
