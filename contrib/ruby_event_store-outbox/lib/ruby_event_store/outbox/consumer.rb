require "logger"
require "redis"
require "active_record"
require "ruby_event_store/outbox/record"
require "ruby_event_store/outbox/sidekiq5_format"

module RubyEventStore
  module Outbox
    class Consumer
      SLEEP_TIME_WHEN_NOTHING_TO_DO = 0.1

      class Configuration
        def initialize(
          split_keys:,
          message_format:,
          batch_size:,
          database_url:,
          redis_url:
        )
          @split_keys = split_keys
          @message_format = message_format
          @batch_size = batch_size || 100
          @database_url = database_url
          @redis_url = redis_url
          freeze
        end

        def with(overriden_options)
          self.class.new(
            split_keys: overriden_options.fetch(:split_keys, split_keys),
            message_format: overriden_options.fetch(:message_format, message_format),
            batch_size: overriden_options.fetch(:batch_size, batch_size),
            database_url: overriden_options.fetch(:database_url, database_url),
            redis_url: overriden_options.fetch(:redis_url, redis_url),
          )
        end

        attr_reader :split_keys, :message_format, :batch_size, :database_url, :redis_url
      end

      def initialize(configuration, clock: Time, logger:, metrics:)
        @split_keys = configuration.split_keys
        @clock = clock
        @redis = Redis.new(url: configuration.redis_url)
        @logger = logger
        @metrics = metrics
        @batch_size = configuration.batch_size
        ActiveRecord::Base.establish_connection(configuration.database_url) unless ActiveRecord::Base.connected?

        raise "Unknown format" if configuration.message_format != SIDEKIQ5_FORMAT
        @message_format = SIDEKIQ5_FORMAT

        @gracefully_shutting_down = false
        prepare_traps
      end

      def init
        @redis.sadd("queues", split_keys)
        logger.info("Initiated RubyEventStore::Outbox v#{VERSION}")
        logger.info("Handling split keys: #{split_keys ? split_keys.join(", ") : "(all of them)"}")
      end

      def run
        while !@gracefully_shutting_down do
          was_something_changed = one_loop
          if !was_something_changed
            STDOUT.flush
            sleep SLEEP_TIME_WHEN_NOTHING_TO_DO
          end
        end
        logger.info "Gracefully shutting down"
      end

      def one_loop
        Record.transaction do
          records_scope = Record.lock.where(format: message_format, enqueued_at: nil)
          records_scope = records_scope.where(split_key: split_keys) if !split_keys.nil?
          records = records_scope.order("id ASC").limit(batch_size).to_a
          if records.empty?
            metrics.write_point_queue(deadlocked: false)
            return false
          end

          now = @clock.now.utc
          failed_record_ids = []
          records.each do |record|
            begin
              handle_one_record(now, record)
            rescue => e
              failed_record_ids << record.id
              e.full_message.split($/).each {|line| logger.error(line) }
            end
          end

          updated_record_ids = records.map(&:id) - failed_record_ids
          Record.where(id: updated_record_ids).update_all(enqueued_at: now)
          metrics.write_point_queue(deadlocked: false, enqueued: updated_record_ids.size, failed: failed_record_ids.size)

          logger.info "Sent #{records.size} messages from outbox table"
          true
        end
      rescue ActiveRecord::Deadlocked
        logger.warn "Outbox fetch deadlocked"
        metrics.write_point_queue(deadlocked: true)
        false
      end

      private
      attr_reader :split_keys, :logger, :message_format, :batch_size, :metrics

      def handle_one_record(now, record)
        hash_payload = JSON.parse(record.payload)
        @redis.lpush("queue:#{hash_payload.fetch("queue")}", JSON.generate(JSON.parse(record.payload).merge({
          "enqueued_at" => now.to_f,
        })))
      end

      def prepare_traps
        Signal.trap("INT") do
          initiate_graceful_shutdown
        end
        Signal.trap("TERM") do
          initiate_graceful_shutdown
        end
      end

      def initiate_graceful_shutdown
        @gracefully_shutting_down = true
      end
    end
  end
end
