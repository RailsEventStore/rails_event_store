require 'spec_helper'

module RubyEventStore
  module Outbox
    RSpec.describe CleanupStrategies::CleanOldEnqueued, db: true, redis: true do
      include SchemaHelper

      let(:redis_url) { RedisIsolation.redis_url }
      let(:database_url) { ENV["DATABASE_URL"] }
      let(:redis) { Redis.new(url: redis_url) }
      let(:logger_output) { StringIO.new }
      let(:logger) { Logger.new(logger_output) }
      let(:default_configuration) { Consumer::Configuration.new(database_url: database_url, redis_url: redis_url, split_keys: ["default", "default2"], message_format: SIDEKIQ5_FORMAT, batch_size: 100, cleanup: :none, sleep_on_empty: 1) }
      let(:metrics) { Metrics::Null.new }

      specify 'clean old jobs' do
        record = create_record("default", "default")
        clock = TickingClock.new
        consumer = Consumer.new(SecureRandom.uuid, default_configuration.with(cleanup: "P7D"), clock: clock, logger: logger, metrics: metrics)
        result = consumer.one_loop
        record.reload
        expect(redis.llen("queue:default")).to eq(1)
        expect(Repository::Record.count).to eq(1)
        travel (7.days + 1.minute)

        consumer.one_loop

        expect(Repository::Record.count).to eq(0)
      end

      def create_record(queue, split_key, format: "sidekiq5")
        payload = {
          class: "SomeAsyncHandler",
          queue: queue,
          created_at: Time.now.utc,
          jid: SecureRandom.hex(12),
          retry: true,
          args: [{
            event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
            event_type: "RubyEventStore::Event",
            data: "--- {}\n",
            metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n",
          }],
        }
        record = Repository::Record.create!(
          split_key: split_key,
          created_at: Time.now.utc,
          format: format,
          enqueued_at: nil,
          payload: payload.to_json
        )
      end
    end
  end
end
