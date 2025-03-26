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
        @locking = configuration.locking

        raise "Unknown format" if configuration.message_format != SIDEKIQ5_FORMAT
        redis_config = RedisClient.config(url: configuration.redis_url)
        @processor = SidekiqProcessor.new(redis_config.new_client)

        @repository = Repository.new(configuration.database_url, logger, metrics)
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
        repository.with_next_batch(fetch_specification, tempo.batch_size, consumer_uuid, locking, @clock) do |record|
          now = @clock.now.utc
          processor.process(record, now)
          repository.mark_as_enqueued(record, now)
        end.tap do
          cleanup(fetch_specification)
          processor.after_batch
        end.success_count > 0
      end

      private

      attr_reader :split_keys,
                  :logger,
                  :metrics,
                  :processor,
                  :consumer_uuid,
                  :repository,
                  :locking,
                  :cleanup_strategy,
                  :tempo

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
    end
  end
end
