require 'spec_helper'
require 'byebug'

module RubyEventStore
  module Outbox
    RSpec.describe Consumer do
      include SchemaHelper

      around(:each) do |example|
        begin
          establish_database_connection
          # load_database_schema
          m = Migrator.new(File.expand_path('../lib/generators/ruby_event_store/outbox/templates', __dir__))
          m.run_migration('create_event_store_outbox')
          example.run
        ensure
          # drop_database
          begin
            ActiveRecord::Migration.drop_table("event_store_outbox")
          rescue ActiveRecord::StatementInvalid
          end
        end
      end

      before(:each) do
        Sidekiq.configure_client do |config|
          config.redis = { url: ENV["REDIS_URL"] }
        end

        Sidekiq.redis_pool.with do |conn|
          conn.flushdb
        end
      end

      specify "updates enqueued_at" do
        payload = {
          class: "SomeAsyncHandler",
          queue: "default",
          created_at: Time.now.utc,
          jid: Time.now.utc,
          retry: true,
          args: [{
            event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
            event_type: "RubyEventStore::Event",
            data: "--- {}\n",
            metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n",
          }],
        }
        record = Record.create!(
          split_key: "default",
          created_at: Time.now.utc,
          format: "sidekiq5",
          enqueued_at: nil,
          payload: payload.to_json
        )
        consumer = Consumer.new(["default"])
        consumer.one_loop

        record.reload
        expect(record.enqueued_at).to be_present
      end

      specify "push the jobs to sidekiq" do
        payload = {
          class: "SomeAsyncHandler",
          queue: "default",
          created_at: Time.now.utc,
          jid: Time.now.utc,
          retry: true,
          args: [{
            event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
            event_type: "RubyEventStore::Event",
            data: "--- {}\n",
            metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n",
          }],
        }
        record = Record.create!(
          split_key: "default",
          created_at: Time.now.utc,
          format: "sidekiq5",
          enqueued_at: nil,
          payload: payload.to_json
        )
        clock = TickingClock.new
        consumer = Consumer.new(["default"], clock: clock)
        result = consumer.one_loop

        Sidekiq.redis_pool.with do |redis|
          expect(redis.llen("queue:default")).to eq(1)
          payload_in_redis = JSON.parse(redis.lindex("queue:default", 0))
          expect(payload_in_redis).to include(payload.as_json)
          expect(payload_in_redis["enqueued_at"]).to eq(clock.tick(0).to_f)
        end
        record.reload
        expect(record.enqueued_at).to eq(clock.tick(0))
        expect(result).to eq(true)
      end

      specify "initiating consumer ensures that queues exist" do
        consumer = Consumer.new(["default"])

        consumer.init

        Sidekiq.redis_pool.with do |redis|
          expect(redis.scard("queues")).to eq(1)
          expect(redis.smembers("queues")).to match_array(["default"])
        end
      end

      specify "returns false if no records" do
        consumer = Consumer.new(["default"])

        result = consumer.one_loop

        expect(result).to eq(false)
      end

      specify "#run wait if nothing was changed" do
        consumer = Consumer.new(["default"])
        expect(consumer).to receive(:one_loop).and_return(false).ordered
        expect(consumer).to receive(:one_loop).and_raise("End infinite loop").ordered
        allow(consumer).to receive(:sleep)

        expect do
          consumer.run
        end.to raise_error("End infinite loop")

        expect(consumer).to have_received(:sleep).with(0.1)
      end

      specify "#run doesnt wait if something changed" do
        consumer = Consumer.new(["default"])
        expect(consumer).to receive(:one_loop).and_return(true).ordered
        expect(consumer).to receive(:one_loop).and_raise("End infinite loop").ordered
        allow(consumer).to receive(:sleep)

        expect do
          consumer.run
        end.to raise_error("End infinite loop")

        expect(consumer).not_to have_received(:sleep)
      end
    end
  end
end
