# frozen_string_literal: true

require "logger"
require "redis-client"
require "active_record"
require_relative "repository"
require_relative "sidekiq5_format"
require_relative "tempo"
require_relative "sidekiq_processor"
require_relative "fetch_specification"
require_relative "cleanup_strategies"
require_relative "batch_result"

module RubyEventStore
  module Outbox
    class Consumer
      MAXIMUM_BATCH_FETCHES_IN_ONE_LOCK = 10

      def initialize(consumer_uuid, configuration, clock: Time, logger:, metrics:)
        @split_keys = configuration.split_keys
        @clock = clock
        @logger = logger
        @metrics = metrics
        @tempo = Tempo.new(configuration.batch_size)
        @consumer_uuid = consumer_uuid

        raise "Unknown format" if configuration.message_format != SIDEKIQ5_FORMAT
        redis_config = RedisClient.config(url: configuration.redis_url)
        @processor = SidekiqProcessor.new(redis_config.new_client)

        @repository = case configuration.repository
          when :locking
            Repository.new(configuration.database_url)
          when :non_locking
            NonLockingRepository.new(configuration.database_url)
          else
            raise ArgumentError, "Unknown repository: #{configuration.repository}"
          end
        @cleanup_strategy = CleanupStrategies.build(configuration, repository)
      end

      def process
        remaining_split_keys = split_keys.dup

        was_something_changed = false
        while (split_key = remaining_split_keys.shift)
          was_something_changed |= handle_split(FetchSpecification.new(processor.message_format, split_key))
        end
        was_something_changed
      end

      def handle_split(fetch_specification)
        obtained_lock = obtain_lock_for_process(fetch_specification)
        return false unless obtained_lock

        something_processed = false

        MAXIMUM_BATCH_FETCHES_IN_ONE_LOCK.times do
          batch = retrieve_batch(fetch_specification)
          break if batch.empty?

          batch_result = BatchResult.empty
          batch.each do |record|
            handle_failure(batch_result) do
              now = @clock.now.utc
              processor.process(record, now)

              repository.mark_as_enqueued(record, now)
              something_processed |= true
              batch_result.count_success!
            end
          end

          metrics.write_point_queue(
            enqueued: batch_result.success_count,
            failed: batch_result.failed_count,
            format: fetch_specification.message_format,
            split_key: fetch_specification.split_key,
            remaining: get_remaining_count(fetch_specification)
          )

          logger.info "Sent #{batch_result.success_count} messages from outbox table"

          refresh_successful = refresh_lock_for_process(obtained_lock)
          break unless refresh_successful
        end

        unless something_processed
          metrics.write_point_queue(
            format: fetch_specification.message_format,
            split_key: fetch_specification.split_key,
            remaining: get_remaining_count(fetch_specification)
          )
        end

        release_lock_for_process(fetch_specification)

        cleanup(fetch_specification)

        processor.after_batch

        something_processed
      end

      private

      attr_reader :split_keys,
                  :logger,
                  :metrics,
                  :processor,
                  :consumer_uuid,
                  :repository,
                  :cleanup_strategy,
                  :tempo

      def handle_failure(batch_result)
        retried = false
        yield
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

      def obtain_lock_for_process(fetch_specification)
        result = repository.obtain_lock_for_process(fetch_specification, consumer_uuid, clock: @clock)
        case result
        when :deadlocked
          logger.warn "Obtaining lock for split_key '#{fetch_specification.split_key}' failed (deadlock)"
          metrics.write_operation_result("obtain", "deadlocked")
          false
        when :lock_timeout
          logger.warn "Obtaining lock for split_key '#{fetch_specification.split_key}' failed (lock timeout)"
          metrics.write_operation_result("obtain", "lock_timeout")
          false
        when :taken
          logger.debug "Obtaining lock for split_key '#{fetch_specification.split_key}' unsuccessful (taken)"
          metrics.write_operation_result("obtain", "taken")
          false
        else
          result
        end
      end

      def release_lock_for_process(fetch_specification)
        result = repository.release_lock_for_process(fetch_specification, consumer_uuid)
        case result
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
      end

      def refresh_lock_for_process(lock)
        result = lock.refresh(clock: @clock)
        case result
        when :ok
          return true
        when :deadlocked
          logger.warn "Refreshing lock for split_key '#{lock.split_key}' failed (deadlock)"
          metrics.write_operation_result("refresh", "deadlocked")
          return false
        when :lock_timeout
          logger.warn "Refreshing lock for split_key '#{lock.split_key}' failed (lock timeout)"
          metrics.write_operation_result("refresh", "lock_timeout")
          return false
        when :stolen
          logger.debug "Refreshing lock for split_key '#{lock.split_key}' unsuccessful (stolen)"
          metrics.write_operation_result("refresh", "stolen")
          return false
        else
          raise "Unexpected result #{result}"
        end
      end

      def cleanup(fetch_specification)
        result = cleanup_strategy.call(fetch_specification)
        case result
        when :deadlocked
          logger.warn "Cleanup for split_key '#{fetch_specification.split_key}' failed (deadlock)"
          metrics.write_operation_result("cleanup", "deadlocked")
        when :lock_timeout
          logger.warn "Cleanup for split_key '#{fetch_specification.split_key}' failed (lock timeout)"
          metrics.write_operation_result("cleanup", "lock_timeout")
        end
      end

      def retrieve_batch(fetch_specification)
        repository.retrieve_batch(fetch_specification, tempo.batch_size)
      end

      def get_remaining_count(fetch_specification)
        repository.get_remaining_count(fetch_specification)
      end
    end
  end
end
