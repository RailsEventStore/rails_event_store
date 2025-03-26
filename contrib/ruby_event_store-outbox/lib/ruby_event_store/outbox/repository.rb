# frozen_string_literal: true

require "active_record"
require "active_support/core_ext/numeric/time.rb"

module RubyEventStore
  module Outbox
    class Repository
      RECENTLY_LOCKED_DURATION = 10.minutes

      class Record < ::ActiveRecord::Base
        self.primary_key = :id
        self.table_name = "event_store_outbox"

        def self.remaining_for(fetch_specification)
          where(format: fetch_specification.message_format, split_key: fetch_specification.split_key, enqueued_at: nil)
        end

        def self.for_fetch_specification(fetch_specification)
          where(format: fetch_specification.message_format, split_key: fetch_specification.split_key)
        end

        def hash_payload
          JSON.parse(payload).deep_symbolize_keys
        end

        def enqueued?
          !enqueued_at.nil?
        end
      end

      class Lock < ::ActiveRecord::Base
        self.table_name = "event_store_outbox_locks"

        def self.obtain(fetch_specification, process_uuid, clock:)
          transaction do
            l = get_lock_record(fetch_specification)

            if l.recently_locked?(clock: clock)
              :taken
            else
              l.update!(locked_by: process_uuid, locked_at: clock.now)
              l
            end
          end
        rescue ::ActiveRecord::Deadlocked
          :deadlocked
        rescue ::ActiveRecord::LockWaitTimeout
          :lock_timeout
        end

        def refresh(clock:)
          transaction do
            current_process_uuid = locked_by
            lock!
            if locked_by == current_process_uuid
              update!(locked_at: clock.now)
              :ok
            else
              :stolen
            end
          end
        rescue ::ActiveRecord::Deadlocked
          :deadlocked
        rescue ::ActiveRecord::LockWaitTimeout
          :lock_timeout
        end

        def self.release(fetch_specification, process_uuid)
          transaction do
            l = get_lock_record(fetch_specification)
            if !l.locked_by?(process_uuid)
              :not_taken_by_this_process
            else
              l.update!(locked_by: nil, locked_at: nil)
              :ok
            end
          end
        rescue ::ActiveRecord::Deadlocked
          :deadlocked
        rescue ::ActiveRecord::LockWaitTimeout
          :lock_timeout
        end

        def locked_by?(process_uuid)
          locked_by.eql?(process_uuid)
        end

        def recently_locked?(clock:)
          locked_by && locked_at > RECENTLY_LOCKED_DURATION.ago(clock.now)
        end

        def fetch_specification
          FetchSpecification.new(format, split_key)
        end

        private

        def self.lock_for_split_key(fetch_specification)
          lock.find_by(format: fetch_specification.message_format, split_key: fetch_specification.split_key)
        end

        def self.get_lock_record(fetch_specification)
          l = lock_for_split_key(fetch_specification)
          if l.nil?
            begin
              l = create!(format: fetch_specification.message_format, split_key: fetch_specification.split_key)
            rescue ::ActiveRecord::RecordNotUnique
              l = lock_for_split_key(fetch_specification)
            end
          end
          l
        end
      end

      def initialize(database_url, logger, metrics)
        @logger = logger
        @metrics = metrics
        ::ActiveRecord::Base.establish_connection(database_url) unless ::ActiveRecord::Base.connected?
        if ::ActiveRecord::Base.connection.adapter_name == "Mysql2"
          ::ActiveRecord::Base.connection.execute("SET SESSION innodb_lock_wait_timeout = 1;")
        end
      end

      def with_next_batch(fetch_specification, batch_size, consumer_uuid, locking, clock, &block)
        if locking
          with_next_locking_batch(fetch_specification, batch_size, consumer_uuid, clock, &block)
        else
          with_next_non_locking_batch(fetch_specification, batch_size, &block)
        end
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

      private

      def with_next_locking_batch(fetch_specification, batch_size, consumer_uuid, clock, &block)
        BatchResult.empty.tap do |result|
          obtained_lock = obtain_lock_for_process(fetch_specification, consumer_uuid, clock: clock)
          case obtained_lock
            when :deadlocked
              logger.warn "Obtaining lock for split_key '#{fetch_specification.split_key}' failed (deadlock)"
              metrics.write_operation_result("obtain", "deadlocked")
              return BatchResult.empty
            when :lock_timeout
              logger.warn "Obtaining lock for split_key '#{fetch_specification.split_key}' failed (lock timeout)"
              metrics.write_operation_result("obtain", "lock_timeout")
              return BatchResult.empty
            when :taken
              logger.debug "Obtaining lock for split_key '#{fetch_specification.split_key}' unsuccessful (taken)"
              metrics.write_operation_result("obtain", "taken")
              return BatchResult.empty
          end

          Consumer::MAXIMUM_BATCH_FETCHES_IN_ONE_LOCK.times do
            batch = retrieve_batch(fetch_specification, batch_size).to_a
            break if batch.empty?
            batch.each do |record|
              handle_execution(result) do
                block.call(record)
              end
            end
            case (refresh_result = obtained_lock.refresh(clock: clock))
              when :ok
              when :deadlocked
                logger.warn "Refreshing lock for split_key '#{lock.split_key}' failed (deadlock)"
                metrics.write_operation_result("refresh", "deadlocked")
                break
              when :lock_timeout
                logger.warn "Refreshing lock for split_key '#{lock.split_key}' failed (lock timeout)"
                metrics.write_operation_result("refresh", "lock_timeout")
                break
              when :stolen
                logger.debug "Refreshing lock for split_key '#{lock.split_key}' unsuccessful (stolen)"
                metrics.write_operation_result("refresh", "stolen")
                break
              else
                raise "Unexpected result #{refresh_result}"
            end
          end

          case release_lock_for_process(fetch_specification, consumer_uuid)
            when :deadlocked
              logger.warn "Releasing lock for split_key '#{fetch_specification.split_key}' failed (deadlock)"
              metrics.write_operation_result("release", "deadlocked")
            when :lock_timeout
              logger.warn "Releasing lock for split_key '#{fetch_specification.split_key}' failed (lock timeout)"
              metrics.write_operation_result("release", "lock_timeout")
            when :not_taken_by_this_process
              logger.debug "Releasing lock for split_key '#{fetch_specification.split_key}' failed (not taken by this process)"
              metrics.write_operation_result("release", "not_taken_by_this_process")
          end
          instrument_batch_result(fetch_specification, result)
        end
      end

      def with_next_non_locking_batch(fetch_specification, batch_size, &block)
        BatchResult.empty.tap do |result|
          Record.transaction do
            batch = retrieve_batch(fetch_specification, batch_size).lock("FOR UPDATE SKIP LOCKED")
            break if batch.empty?
            batch.each do |record|
              handle_execution(result) do
                block.call(record)
              end
            end
          end

          instrument_batch_result(fetch_specification, result)
        end
      end

      def instrument_batch_result(fetch_specification, result)
        metrics.write_point_queue(
          enqueued: result.success_count,
          failed: result.failed_count,
          format: fetch_specification.message_format,
          split_key: fetch_specification.split_key,
          remaining: Record.remaining_for(fetch_specification).count
        )

        logger.info "Sent #{result.success_count} messages from outbox table"
      end

      def handle_execution(batch_result)
        retried = false
        yield
        batch_result.count_success!
      rescue RetriableRedisError => error
        if retried
          batch_result.count_failed!
          log_error(error)
        else
          retried = true
          retry
        end
      rescue => error
        batch_result.count_failed!
        log_error(error)
      end

      def log_error(e)
        e.full_message.split($/).each { |line| logger.error(line) }
      end

      def retrieve_batch(fetch_specification, batch_size)
        Record.remaining_for(fetch_specification).order("id ASC").limit(batch_size)
      end

      def obtain_lock_for_process(fetch_specification, process_uuid, clock:)
        Lock.obtain(fetch_specification, process_uuid, clock: clock)
      end

      def release_lock_for_process(fetch_specification, process_uuid)
        Lock.release(fetch_specification, process_uuid)
      end

      attr_reader :logger, :metrics
    end
  end
end
