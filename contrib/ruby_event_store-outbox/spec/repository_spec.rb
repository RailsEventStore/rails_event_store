# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Outbox
    ::RSpec.describe Repository, db: true do
      include SchemaHelper

      let(:database_url) { ENV["DATABASE_URL"] }
      let(:message_format) { "some_message_format" }
      let(:split_key) { "some_split_key" }
      let(:some_process_uuid) { SecureRandom.uuid }
      let(:other_process_uuid) { SecureRandom.uuid }
      let(:clock) { TickingClock.new }
      let(:logger) { Logger.new(logger_output) }
      let(:logger_output) { StringIO.new }
      let(:null_metrics) { Metrics::Null.new }

      specify "successful obtaining returns Lock structure" do
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)

        lock = Repository::Lock.obtain(expected_fetch_specification, some_process_uuid, clock: clock)

        expect(lock).to be_a(Repository::Lock)
        expect(lock.fetch_specification).to eq(expected_fetch_specification)
        expect(lock).to be_locked_by(some_process_uuid)
        expect(lock).to be_recently_locked(clock: clock)
      end

      specify "Lock is not considered locked after some time" do
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)

        result = Repository::Lock.obtain(expected_fetch_specification, some_process_uuid, clock: clock)
        wait_for_lock_duration

        expect(result).not_to be_recently_locked(clock: clock)
      end

      specify "trying to obtain taken Lock" do
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)
        Repository::Lock.obtain(expected_fetch_specification, some_process_uuid, clock: clock)

        result = Repository::Lock.obtain(expected_fetch_specification, other_process_uuid, clock: clock)

        expect(result).to be(:taken)
      end

      specify "obtains a lock for given fetch specification" do
        Repository::Lock.obtain(
          FetchSpecification.new("other_message_format", split_key),
          some_process_uuid,
          clock: clock
        )
        Repository::Lock.obtain(
          FetchSpecification.new(message_format, "other_split_key"),
          some_process_uuid,
          clock: clock
        )
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)

        lock = Repository::Lock.obtain(expected_fetch_specification, some_process_uuid, clock: clock)

        expect(lock.fetch_specification).to eq(expected_fetch_specification)
      end

      specify "successful release" do
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)
        lock = Repository::Lock.obtain(expected_fetch_specification, some_process_uuid, clock: clock)

        result = Repository::Lock.release(expected_fetch_specification, some_process_uuid)

        expect(result).to be(:ok)
        lock.reload
        expect(lock.locked_by).to be_nil
        expect(lock.locked_at).to be_nil
      end

      specify "released lock can be obtained by other process" do
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)
        Repository::Lock.obtain(expected_fetch_specification, some_process_uuid, clock: clock)

        Repository::Lock.release(expected_fetch_specification, some_process_uuid)

        result = Repository::Lock.obtain(expected_fetch_specification, other_process_uuid, clock: clock)
        expect(result).to be_a(Repository::Lock)
      end

      specify "cant release not obtained lock" do
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)

        result = Repository::Lock.release(expected_fetch_specification, some_process_uuid)

        expect(result).to be(:not_taken_by_this_process)
      end

      specify "one process cant release other's lock" do
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)
        Repository::Lock.obtain(expected_fetch_specification, some_process_uuid, clock: clock)

        result = Repository::Lock.release(expected_fetch_specification, other_process_uuid)

        expect(result).to be(:not_taken_by_this_process)
      end

      specify "lock timeout when obtaining Lock" do
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)
        expect(Repository::Lock).to receive(:lock).and_raise(::ActiveRecord::LockWaitTimeout)

        result = Repository::Lock.obtain(expected_fetch_specification, some_process_uuid, clock: clock)

        expect(result).to be(:lock_timeout)
      end

      specify "deadlock when obtaining Lock" do
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)
        expect(Repository::Lock).to receive(:create!).and_raise(::ActiveRecord::Deadlocked)

        result = Repository::Lock.obtain(expected_fetch_specification, some_process_uuid, clock: clock)

        expect(result).to be(:deadlocked)
      end

      specify "lock timeout when releasing lock" do
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)
        Repository::Lock.obtain(expected_fetch_specification, some_process_uuid, clock: clock)
        expect(Repository::Lock).to receive(:lock).and_raise(::ActiveRecord::LockWaitTimeout)

        result = Repository::Lock.release(expected_fetch_specification, some_process_uuid)

        expect(result).to be(:lock_timeout)
      end

      specify "deadlock when releasing lock" do
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)
        Repository::Lock.obtain(expected_fetch_specification, some_process_uuid, clock: clock)
        expect(Repository::Lock).to receive(:lock).and_raise(::ActiveRecord::Deadlocked)

        result = Repository::Lock.release(expected_fetch_specification, some_process_uuid)

        expect(result).to be(:deadlocked)
      end

      specify "refreshing lock" do
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)
        lock = Repository::Lock.obtain(expected_fetch_specification, some_process_uuid, clock: clock)
        clock.test_travel (Repository::RECENTLY_LOCKED_DURATION / 2)

        result = lock.refresh(clock: clock)

        clock.test_travel (Repository::RECENTLY_LOCKED_DURATION / 2 + 1.second)
        expect(result).to be(:ok)
        expect(lock).to be_locked_by(some_process_uuid)
        expect(lock).to be_recently_locked(clock: clock)
      end

      specify "refreshing lock when other process stole it" do
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)
        lock_for_some_process =
          Repository::Lock.obtain(expected_fetch_specification, some_process_uuid, clock: clock)
        wait_for_lock_duration
        Repository::Lock.obtain(expected_fetch_specification, other_process_uuid, clock: clock)

        result = lock_for_some_process.refresh(clock: clock)

        expect(result).to be(:stolen)
      end

      specify "lock timeout when refreshing lock" do
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)
        lock = Repository::Lock.obtain(expected_fetch_specification, some_process_uuid, clock: clock)
        expect(lock).to receive(:lock!).and_raise(::ActiveRecord::LockWaitTimeout)

        result = lock.refresh(clock: clock)

        expect(result).to be(:lock_timeout)
      end

      specify "deadlocked when refreshing lock" do
        expected_fetch_specification = FetchSpecification.new(message_format, split_key)
        lock = Repository::Lock.obtain(expected_fetch_specification, some_process_uuid, clock: clock)
        expect(lock).to receive(:lock!).and_raise(::ActiveRecord::Deadlocked)

        result = lock.refresh(clock: clock)

        expect(result).to be(:deadlocked)
      end

      def wait_for_lock_duration
        clock.test_travel (Repository::RECENTLY_LOCKED_DURATION + 1.second)
      end
    end
  end
end
