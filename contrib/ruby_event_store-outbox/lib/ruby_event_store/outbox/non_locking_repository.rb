# frozen_string_literal: true

require "active_record"
require "active_support/core_ext/numeric/time.rb"

module RubyEventStore
  module Outbox
    class NonLockingRepository
      RECENTLY_LOCKED_DURATION = 10.minutes

      ConcurrencyError = Class.new(StandardError)

      class Lock
        attr_reader :locked_by, :locked_at, :format, :split_key

        def initialize(locked_by, locked_at, format, split_key)
          @locked_at = locked_at
          @locked_by = locked_by
          @format = format
          @split_key = split_key
        end

        def self.obtain(fetch_specification, process_uuid, clock:)
          new(process_uuid, clock.now, fetch_specification.message_format, fetch_specification.split_key)
        end

        def refresh(clock:)
          @locked_at = clock.now
          :ok
        end

        def self.release(*)
          :ok
        end

        def locked_by?(process_uuid)
          locked_by.eql?(process_uuid)
        end

        def recently_locked?(clock:)
          locked_by && locked_at > RECENTLY_LOCKED_DURATION.ago(clock.now)
        end
      end

      class Record < ::ActiveRecord::Base
        self.primary_key = :id
        self.table_name = "event_store_outbox"

        def self.remaining_for(fetch_specification)
          transaction do
            where(format: fetch_specification.message_format, split_key: fetch_specification.split_key, enqueued_at: nil).lock("FOR UPDATE SKIP LOCKED")
          end
        end

        def self.for_fetch_specification(fetch_specification)
          transaction do
            where(format: fetch_specification.message_format, split_key: fetch_specification.split_key).lock("FOR UPDATE SKIP LOCKED")
          end
        end

        def hash_payload
          JSON.parse(payload).deep_symbolize_keys
        end

        def enqueued?
          !enqueued_at.nil?
        end
      end

      def initialize(database_url)
        ::ActiveRecord::Base.establish_connection(database_url) unless ::ActiveRecord::Base.connected?
        raise "sqlite does not support SKIP LOCKED" if ::ActiveRecord::Base.connection.adapter_name == "SQLite"
        if ::ActiveRecord::Base.connection.adapter_name == "Mysql2"
          ::ActiveRecord::Base.connection.execute("SET SESSION innodb_lock_wait_timeout = 1;")
        end
      end

      def retrieve_batch(fetch_specification, batch_size)
        Record.remaining_for(fetch_specification).order("id ASC").limit(batch_size).to_a
      end

      def get_remaining_count(fetch_specification)
        Record.remaining_for(fetch_specification).count
      end

      def obtain_lock_for_process(fetch_specification, process_uuid, clock:)
        Lock.obtain(fetch_specification, process_uuid, clock: clock)
      end

      def release_lock_for_process(fetch_specification, process_uuid)
        Lock.release(fetch_specification, process_uuid)
      end

      def mark_as_enqueued(record, now)
        record.update_column(:enqueued_at, now)
      end

      def delete_enqueued_older_than(fetch_specification, duration, limit)
        scope = Record.for_fetch_specification(fetch_specification).where("enqueued_at < ?", duration.ago)
        scope = scope.limit(limit).order(:id) unless limit == :all
        scope.delete_all
        :ok
      rescue ::ActiveRecord::Deadlocked
        :deadlocked
      rescue ::ActiveRecord::LockWaitTimeout
        :lock_timeout
      end
    end
  end
end
