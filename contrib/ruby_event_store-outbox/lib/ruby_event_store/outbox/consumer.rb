module RubyEventStore
  module Outbox
    class Consumer
      def initialize(clock: Time)
        @clock = clock
        @redis_pool = Sidekiq.redis_pool
      end

      def one_loop
        Record.transaction do
          records = Record.lock.where(format: SidekiqScheduler::SIDEKIQ5_FORMAT, enqueued_at: nil).order("id ASC").limit(100)

          now = @clock.now.utc
          records.each do |record|
            hash_payload = JSON.parse(record.payload)
            @redis_pool.with do |redis|
              redis.lpush("queue:#{record.split_key}", JSON.generate(JSON.parse(record.payload).merge({
                "enqueued_at" => now.to_f,
              })))
            end
          end

          records.update_all(enqueued_at: now)
        end
      end
    end
  end
end
