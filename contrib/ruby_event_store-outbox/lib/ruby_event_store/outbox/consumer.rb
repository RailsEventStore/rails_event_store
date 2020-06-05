module RubyEventStore
  module Outbox
    class Consumer
      def initialize
        @sidekiq_client = Sidekiq::Client.new(Sidekiq.redis_pool)
      end

      def one_loop
        Record.transaction do
          records = Record.lock.where(format: SidekiqScheduler::SIDEKIQ5_FORMAT, enqueued_at: nil).order("id ASC").limit(100)

          records.each do |record|
            hash_payload = JSON.parse(record.payload)
            @sidekiq_client.__send__(:raw_push, [hash_payload])
          end

          now = Time.now.utc
          records.update_all(enqueued_at: now)
        end
      end
    end
  end
end
