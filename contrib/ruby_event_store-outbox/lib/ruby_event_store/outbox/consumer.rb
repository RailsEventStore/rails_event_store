require "logger"
require "redis"
require "active_record"
require "ruby_event_store/outbox/record"
require "ruby_event_store/outbox/sidekiq_scheduler"

module RubyEventStore
  module Outbox
    class Consumer
      def initialize(split_keys, clock: Time, logger: Logger.new(STDOUT))
        @split_keys = split_keys
        @clock = clock
        @redis = Redis.new(url: ENV["REDIS_URL"])
        @logger = logger
        ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
      end

      def init
        @redis.sadd("queues", split_keys)
        logger.info("Initiated RubyEventStore::Outbox v#{VERSION}")
      end

      def run
        loop do
          was_something_changed = one_loop
          sleep 0.1 if !was_something_changed
        end
      end

      def one_loop
        Record.transaction do
          records = Record.lock.where(format: SidekiqScheduler::SIDEKIQ5_FORMAT, enqueued_at: nil).order("id ASC").limit(100)
          return false if records.empty?

          now = @clock.now.utc
          records.each do |record|
            hash_payload = JSON.parse(record.payload)
            @redis.lpush("queue:#{hash_payload.fetch("queue")}", JSON.generate(JSON.parse(record.payload).merge({
              "enqueued_at" => now.to_f,
            })))
          end

          records.update_all(enqueued_at: now)
          logger.info "Sent #{records.size} messages from outbox table"
          return true
        end
      end

      private
      attr_reader :split_keys, :logger
    end
  end
end
