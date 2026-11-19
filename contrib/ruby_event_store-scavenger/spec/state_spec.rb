# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Scavenger
    ::RSpec.describe State do
      let(:clock) { FakeClock.new(Time.utc(2026, 11, 18, 12, 0, 0)) }
      let(:state) { State.new(clock: clock) }

      def rows
        ::ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{State::TABLE}")
      end

      specify "initial status without a record" do
        expect(state.status).to eq(Status.initial)
      end

      specify "saves the status" do
        state.save(status: :marking, stream: "Order$1", cursor: "Order$0")

        expect(state.status).to eq(
          Status.new(status: :marking, stream: "Order$1", cursor: "Order$0", updated_at: clock.call),
        )
      end

      specify "updates the one record" do
        state.save(status: :marking, stream: "Order$1", cursor: nil)
        clock.advance(5)
        state.save(status: :idle, stream: nil, cursor: "Order$1")

        expect(state.status).to eq(Status.new(status: :idle, stream: nil, cursor: "Order$1", updated_at: clock.call))
        expect(rows).to eq(1)
      end

      specify "reads and writes only its own record" do
        ::ActiveRecord::Base.connection.execute(
          "INSERT INTO #{State::TABLE} (name, status, last_stream, updated_at) VALUES ('other', 'sweeping', 'x', '2000-01-01 00:00:00')",
        )

        expect(state.status).to eq(Status.initial)
        state.save(status: :marking, stream: "a", cursor: nil)

        expect(
          ::ActiveRecord::Base.connection.select_rows(
            "SELECT status, last_stream FROM #{State::TABLE} WHERE name = 'other'",
          ),
        ).to eq([%w[sweeping x]])
      end

      specify "uses the connection of the base class" do
        State.new(base: CustomApplicationRecord, clock: clock).save(status: :sweeping, stream: "a", cursor: nil)

        expect(state.status.status).to eq(:sweeping)
      end

      specify "default clock" do
        State.new.save(status: :idle, stream: nil, cursor: nil)

        expect(State.new.status.updated_at).to be_within(5).of(Time.now.utc)
      end

      describe "claim" do
        specify "claims a free lock" do
          expect(state.claim("a", stale_before: clock.call - 3600)).to be(true)
          expect(rows).to eq(1)
          expect(state.status).to eq(Status.initial.with(updated_at: clock.call))
        end

        specify "refuses a lock another owner holds" do
          state.claim("a", stale_before: clock.call - 3600)

          expect(state.claim("b", stale_before: clock.call - 3600)).to be(false)
          expect(state.claim("a", stale_before: clock.call - 3600)).to be(false)
        end

        specify "takes over a lock taken before stale_before" do
          state.claim("a", stale_before: clock.call - 3600)
          taken_at = clock.call
          clock.advance(10)

          expect(state.claim("b", stale_before: taken_at)).to be(false)
          expect(state.claim("b", stale_before: taken_at + 1)).to be(true)
          expect(state.claim("a", stale_before: taken_at + 1)).to be(false)
        end

        specify "keeps the status" do
          state.save(status: :idle, stream: nil, cursor: "Order$1")

          state.claim("a", stale_before: clock.call - 3600)

          expect(state.status.cursor).to eq("Order$1")
          expect(rows).to eq(1)
        end

        specify "release frees the lock" do
          state.claim("a", stale_before: clock.call - 3600)

          state.release("a")

          expect(state.claim("b", stale_before: clock.call - 3600)).to be(true)
        end

        specify "release clears the lock columns" do
          state.claim("a", stale_before: clock.call - 3600)

          state.release("a")

          expect(::ActiveRecord::Base.connection.select_rows("SELECT locked_by, locked_at FROM #{State::TABLE}")).to eq(
            [[nil, nil]],
          )
        end

        specify "release by another owner keeps the lock" do
          state.claim("a", stale_before: clock.call - 3600)

          state.release("b")

          expect(state.claim("b", stale_before: clock.call - 3600)).to be(false)
        end
      end
    end

    ::RSpec.describe Status, db: false do
      specify "initial" do
        expect(Status.initial).to eq(Status.new(status: :idle, stream: nil, cursor: nil, updated_at: nil))
      end

      specify "to_s" do
        status =
          Status.new(
            status: :sweeping,
            stream: "Order$2",
            cursor: "Order$1",
            updated_at: Time.utc(2026, 11, 18, 12, 0, 0, 5),
          )

        expect(status.to_s).to eq(<<~EOS.chomp)
          status: sweeping
          stream: Order$2
          cursor: Order$1
          updated_at: 2026-11-18T12:00:00.000005Z
        EOS
      end

      specify "to_s of the initial status" do
        expect(Status.initial.to_s).to eq("status: idle\nstream: -\ncursor: -\nupdated_at: -")
      end
    end
  end
end
