require "logger"
require "redis"
require "active_record"
require_relative "repository"
require_relative "sidekiq5_format"
require_relative "sidekiq_processor"
require_relative "fetch_specification"
require_relative "cleanup_strategies/none"
require_relative "cleanup_strategies/clean_old_enqueued"

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
        @processor = SidekiqProcessor.new(Redis.new(url: configuration.redis_url))

        @repository = Repository.new(configuration.database_url)
        @cleanup_strategy =
          case configuration.cleanup
          when :none
            CleanupStrategies::None.new
          else
            CleanupStrategies::CleanOldEnqueued.new(
              repository,
              ActiveSupport::Duration.parse(configuration.cleanup),
              configuration.cleanup_limit
            )
          end
      end

      def init
        logger.info("Initiated RubyEventStore::Outbox v#{VERSION}")
        logger.info("Handling split keys: #{split_keys ? split_keys.join(", ") : "(all of them)"}")
      end

      def one_loop
        remaining_split_keys = @split_keys.dup

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

          failed_record_ids = []
          updated_record_ids = []
          batch.each do |record|
            retried = false
            begin
              now = @clock.now.utc
              processor.process(record, now)

              repository.mark_as_enqueued(record, now)
              something_processed |= true
              updated_record_ids << record.id
            rescue RetriableError => e
              if retried
                failed_record_ids << record.id
                e.full_message.split($/).each { |line| logger.error(line) }
              else
                retried = true
                retry
              end
            rescue => e
              failed_record_ids << record.id
              e.full_message.split($/).each { |line| logger.error(line) }
            end
          end

          metrics.write_point_queue(
            enqueued: updated_record_ids.size,
            failed: failed_record_ids.size,
            format: fetch_specification.message_format,
            split_key: fetch_specification.split_key,
            remaining: get_remaining_count(fetch_specification)
          )

          logger.info "Sent #{updated_record_ids.size} messages from outbox table"

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
