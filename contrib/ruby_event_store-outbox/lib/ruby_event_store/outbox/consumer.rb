module RubyEventStore
  module Outbox
    class Consumer
      def initialize(split_keys, clock: Time)
        @split_keys = split_keys
        @clock = clock
        @redis = Redis.new(url: ENV["REDIS_URL"])
        ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
      end

      def init
        @redis.sadd("queues", split_keys)
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
          return true
        end
      end

      private
      attr_reader :split_keys
    end
  end
end
