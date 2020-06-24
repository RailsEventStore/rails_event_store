require "logger"
require "redis"
require "active_record"
require "ruby_event_store/outbox/record"
require "ruby_event_store/outbox/sidekiq5_format"

module RubyEventStore
  module Outbox
    class Consumer
      SLEEP_TIME_WHEN_NOTHING_TO_DO = 0.1

      def initialize(options, clock: Time, logger:)
        @split_keys = options.split_keys
        @clock = clock
        @redis = Redis.new(url: options.redis_url)
        @logger = logger
        @batch_size = options.batch_size
        ActiveRecord::Base.establish_connection(options.database_url) unless ActiveRecord::Base.connected?

        raise "Unknown format" if options.message_format != SIDEKIQ5_FORMAT
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
          return false if records.empty?

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

          Record.where(id: records.map(&:id) - failed_record_ids).update_all(enqueued_at: now)

          logger.info "Sent #{records.size} messages from outbox table"
          return true
        end
      rescue ActiveRecord::Deadlocked
        logger.warn "Outbox fetch deadlocked"
        false
      end

      private
      attr_reader :split_keys, :logger, :message_format, :batch_size

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
