# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Scavenger
    ::RSpec.describe Lock do
      let(:helper) { SpecHelper.new }
      let(:clock) { FakeClock.new(Time.utc(2026, 11, 18, 12, 0, 0)) }
      let(:state) { State.new(clock: clock) }

      def lock(owner, **options)
        Lock.new(state: state, clock: clock, owner: owner, **options)
      end

      # Tries the lock from a connection of its own: an advisory lock can be taken again on the
      # connection that holds it.
      def taken_elsewhere?(lock)
        return lock.synchronize {} if helper.sqlite?
        Thread.new { lock.synchronize {} }.value
      end

      specify "runs the block and returns true" do
        ran = []

        expect(lock("a").synchronize { ran << 1 }).to be(true)
        expect(ran).to eq([1])
      end

      specify "refuses while another holds it" do
        ran = []
        held = Queue.new
        done = Queue.new
        holder =
          Thread.new do
            lock("a").synchronize do
              held << true
              done.pop
            end
          end unless helper.sqlite?

        if helper.sqlite?
          lock("a").synchronize { expect(lock("b").synchronize { ran << 1 }).to be(false) }
        else
          held.pop
          expect(lock("b").synchronize { ran << 1 }).to be(false)
          done << true
          holder.join
        end

        expect(ran).to eq([])
      end

      specify "is free again after the block" do
        lock("a").synchronize {}

        expect(taken_elsewhere?(lock("b"))).to be(true)
      end

      specify "is free again after the block raised" do
        expect { lock("a").synchronize { raise "boom" } }.to raise_error("boom")

        expect(taken_elsewhere?(lock("b"))).to be(true)
      end

      specify "builds its state on the base class by default" do
        allow(State).to receive(:new).and_call_original

        Lock.new(base: CustomApplicationRecord)

        expect(State).to have_received(:new).with(base: CustomApplicationRecord)
      end

      specify "uses the connection of the base class" do
        expect(Lock.new(base: CustomApplicationRecord, state: state).synchronize {}).to be(true)
      end

      context "without advisory locks" do
        let(:connection) do
          instance_double(::ActiveRecord::ConnectionAdapters::AbstractAdapter, adapter_name: "SQLite")
        end
        let(:pool) { instance_double(::ActiveRecord::ConnectionAdapters::ConnectionPool) }
        let(:base) { class_double(::ActiveRecord::Base, connection_pool: pool) }

        before { allow(pool).to receive(:with_connection).and_yield(connection) }

        def table_lock(owner, stale_after: 3600)
          Lock.new(base: base, state: state, clock: clock, owner: owner, stale_after: stale_after)
        end

        specify "claims the state" do
          table_lock("a").synchronize { expect(state.claim("b", stale_before: clock.call - 3600)).to be(false) }
          expect(state.claim("b", stale_before: clock.call - 3600)).to be(true)
        end

        specify "takes over a lock older than stale_after" do
          state.claim("a", stale_before: clock.call)
          clock.advance(3600)

          expect(table_lock("b").synchronize {}).to be(false)

          clock.advance(1)
          expect(table_lock("b").synchronize {}).to be(true)
        end

        specify "with stale_after given" do
          state.claim("a", stale_before: clock.call)
          clock.advance(61)

          expect(table_lock("b", stale_after: 60).synchronize {}).to be(true)
        end

        specify "default owner is unique" do
          expect(Lock.new(base: base, state: state, clock: clock).synchronize { table_lock("b").synchronize {} }).to be(
            true,
          )
          expect(state.claim("b", stale_before: clock.call - 3600)).to be(true)
        end

        specify "default owner names host and process" do
          owners = []
          allow(state).to receive(:claim).and_wrap_original { |original, owner, **kw|
            owners << owner
            original.call(owner, **kw)
          }

          Lock.new(base: base, state: state, clock: clock).synchronize {}

          expect(owners.first).to match(/\A#{Regexp.escape(Socket.gethostname)}:#{Process.pid}:\h{8}\z/)
        end

        specify "default stale_after is an hour" do
          taken_at = clock.call
          state.claim("a", stale_before: taken_at)
          lock_at = ->(time) { Lock.new(base: base, state: state, clock: -> { time }, owner: "b") }

          expect(lock_at.call(taken_at + 3600).synchronize {}).to be(false)
          expect(lock_at.call(taken_at + 3600 + Rational(1, 1_000_000)).synchronize {}).to be(true)
        end

        specify "default clock" do
          expect(Lock.new(base: base, state: State.new).synchronize {}).to be(true)
          expect(Lock.new(base: base, state: State.new).synchronize {}).to be(true)
        end
      end

      context "with advisory locks" do
        let(:connection) { instance_double(::ActiveRecord::ConnectionAdapters::AbstractAdapter) }
        let(:pool) { instance_double(::ActiveRecord::ConnectionAdapters::ConnectionPool) }
        let(:base) { class_double(::ActiveRecord::Base, connection_pool: pool) }
        let(:state) { instance_double(State) }

        before { allow(pool).to receive(:with_connection).and_yield(connection) }

        {
          "PostgreSQL" => [Lock::POSTGRESQL, true],
          "PostGIS" => [Lock::POSTGRESQL, true],
          "Mysql2" => [Lock::MYSQL, 1],
          "Trilogy" => [Lock::MYSQL, 1],
        }.each do |adapter_name, (advisory, acquired)|
          specify "#{adapter_name} takes and releases #{advisory.acquire}" do
            allow(connection).to receive(:adapter_name).and_return(adapter_name)
            allow(connection).to receive(:select_value).with(advisory.acquire).and_return(acquired)
            allow(connection).to receive(:select_value).with(advisory.release).and_return(acquired)
            ran = []

            expect(Lock.new(base: base, state: state).synchronize { ran << 1 }).to be(true)
            expect(ran).to eq([1])
            expect(connection).to have_received(:select_value).with(advisory.release).ordered
          end

          specify "#{adapter_name} refuses when not acquired" do
            allow(connection).to receive(:adapter_name).and_return(adapter_name)
            allow(connection).to receive(:select_value).with(advisory.acquire).and_return(
              acquired.equal?(true) ? false : 0,
            )
            ran = []

            expect(Lock.new(base: base, state: state).synchronize { ran << 1 }).to be(false)
            expect(ran).to eq([])
            expect(connection).not_to have_received(:select_value).with(advisory.release)
          end
        end

        specify "advisory SQL" do
          expect(Lock::POSTGRESQL).to eq(
            Lock::Advisory.new(
              acquire: "SELECT pg_try_advisory_lock(hashtext('res_scavenger'))",
              release: "SELECT pg_advisory_unlock(hashtext('res_scavenger'))",
              acquired: true,
            ),
          )
          expect(Lock::MYSQL).to eq(
            Lock::Advisory.new(
              acquire: "SELECT GET_LOCK('res_scavenger', 0)",
              release: "SELECT RELEASE_LOCK('res_scavenger')",
              acquired: 1,
            ),
          )
        end
      end
    end
  end
end
