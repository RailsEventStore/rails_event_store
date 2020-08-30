require "logger"
require "redis"
require "active_record"
require "ruby_event_store/outbox/record"
require "ruby_event_store/outbox/sidekiq5_format"
require "ruby_event_store/outbox/sidekiq_processor"

module RubyEventStore
  module Outbox
    class Consumer
      SLEEP_TIME_WHEN_NOTHING_TO_DO = 0.1
      MAXIMUM_BATCH_FETCHES_IN_ONE_LOCK = 10

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

      def initialize(consumer_uuid, configuration, clock: Time, logger:, metrics:)
        @split_keys = configuration.split_keys
        @clock = clock
        @logger = logger
        @metrics = metrics
        @batch_size = configuration.batch_size
        @consumer_uuid = consumer_uuid
        ActiveRecord::Base.establish_connection(configuration.database_url) unless ActiveRecord::Base.connected?
        if ActiveRecord::Base.connection.adapter_name == "Mysql2"
          ActiveRecord::Base.connection.execute("SET SESSION innodb_lock_wait_timeout = 1;")
        end

        raise "Unknown format" if configuration.message_format != SIDEKIQ5_FORMAT
        @processor = SidekiqProcessor.new(Redis.new(url: configuration.redis_url))

        @gracefully_shutting_down = false
        prepare_traps
      end

      def init
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
        remaining_split_keys = @split_keys.dup

        was_something_changed = false
        while (split_key = remaining_split_keys.shift)
          was_something_changed |= handle_split(split_key)
        end
        was_something_changed
      end

      def handle_split(split_key)
        obtained_lock = obtain_lock_for_process(split_key)
        return false unless obtained_lock

        something_processed = false

        MAXIMUM_BATCH_FETCHES_IN_ONE_LOCK.times do
          batch = retrieve_batch(obtained_lock.format, obtained_lock.split_key)
          if batch.empty?
            metrics.write_point_queue(status: "ok", operation: "process")
            break
          end

          failed_record_ids = []
          updated_record_ids = []
          batch.each do |record|
            begin
              now = @clock.now.utc
              processor.process(record, now)

              record.update_column(:enqueued_at, now)
              something_processed |= true
              updated_record_ids << record.id
            rescue => e
              failed_record_ids << record.id
              e.full_message.split($/).each {|line| logger.error(line) }
            end
          end

          metrics.write_point_queue(status: "ok", operation: "process", enqueued: updated_record_ids.size, failed: failed_record_ids.size)

          logger.info "Sent #{updated_record_ids.size} messages from outbox table"

          obtained_lock = refresh_lock_for_process(obtained_lock)
          break unless obtained_lock
        end

        release_lock_for_process(obtained_lock.format, obtained_lock.split_key)

        processor.after_batch

        something_processed
      end

      private
      attr_reader :split_keys, :logger, :batch_size, :metrics, :processor, :consumer_uuid

      def obtain_lock_for_process(split_key)
        result = Lock.obtain(processor.message_format, split_key, consumer_uuid, clock: @clock)
        case result
        when :deadlocked
          logger.warn "Obtaining lock for split_key '#{split_key}' failed (deadlock)"
          metrics.write_point_queue(status: "deadlocked", operation: "obtain")
          return false
        when :lock_timeout
          logger.warn "Obtaining lock for split_key '#{split_key}' failed (lock timeout)"
          metrics.write_point_queue(status: "lock_timeout", operation: "obtain")
          return false
        when :taken
          logger.debug "Obtaining lock for split_key '#{split_key}' unsuccessful (taken)"
          metrics.write_point_queue(status: "taken", operation: "obtain")
          return false
        else
          return result
        end
      end

      def release_lock_for_process(message_format, split_key)
        result = Lock.release(message_format, split_key, consumer_uuid)
        case result
        when :ok
        when :deadlocked
          logger.warn "Releasing lock for split_key '#{split_key}' failed (deadlock)"
          metrics.write_point_queue(status: "deadlocked", operation: "release")
        when :lock_timeout
          logger.warn "Releasing lock for split_key '#{split_key}' failed (lock timeout)"
          metrics.write_point_queue(status: "lock_timeout", operation: "release")
        when :not_taken_by_this_process
          logger.debug "Releasing lock for split_key '#{split_key}' failed (not taken by this process)"
          metrics.write_point_queue(status: "not_taken_by_this_process", operation: "release")
        else
          raise "Unexpected result #{result}"
        end
      end

      def refresh_lock_for_process(lock)
        result = lock.refresh(clock: @clock)
        case result
        when :deadlocked
          logger.warn "Refreshing lock for split_key '#{split_key}' failed (deadlock)"
          metrics.write_point_queue(status: "deadlocked", operation: "refresh")
          return false
        when :lock_timeout
          logger.warn "Refreshing lock for split_key '#{split_key}' failed (lock timeout)"
          metrics.write_point_queue(status: "lock_timeout", operation: "refresh")
          return false
        when :stolen
          logger.debug "Refreshing lock for split_key '#{split_key}' unsuccessful (stolen)"
          metrics.write_point_queue(status: "stolen", operation: "refresh")
          return false
        else
          return result
        end
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

      def retrieve_batch(message_format, split_key)
        records = Record.where(format: message_format, enqueued_at: nil, split_key: split_key).order("id ASC").limit(batch_size).to_a
        records
      end
    end
  end
end
