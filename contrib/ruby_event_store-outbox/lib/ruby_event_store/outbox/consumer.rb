module RubyEventStore
  module Outbox
    class Consumer
      def initialize(split_keys, clock: Time)
        @split_keys = split_keys
        @clock = clock
        @redis_pool = Sidekiq.redis_pool
      end

      def init
        @redis_pool.with do |redis|
          redis.sadd("queues", split_keys)
        end
      end

      def one_loop
        Record.transaction do
          records = Record.lock.where(format: SidekiqScheduler::SIDEKIQ5_FORMAT, enqueued_at: nil).order("id ASC").limit(100)
          return false if records.empty?

          now = @clock.now.utc
          records.each do |record|
            hash_payload = JSON.parse(record.payload)
            @redis_pool.with do |redis|
              redis.lpush("queue:#{hash_payload.fetch("queue")}", JSON.generate(JSON.parse(record.payload).merge({
                "enqueued_at" => now.to_f,
              })))
            end
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
