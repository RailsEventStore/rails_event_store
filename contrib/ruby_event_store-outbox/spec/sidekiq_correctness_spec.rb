require 'spec_helper'
require_relative './support/sidekiq'

module RubyEventStore
  module Outbox
    RSpec.describe "Sidekiq correctness spec", db: true do
      include SchemaHelper
      let(:redis_url) { ENV["REDIS_URL"] }
      let(:database_url) { ENV["DATABASE_URL"] }
      let(:redis) { Redis.new(url: redis_url) }
      let(:test_logger) { Logger.new(StringIO.new) }
      let(:default_options) { CLI::Options.new(database_url, redis_url, :info, ["default"], SIDEKIQ5_FORMAT, 100) }

      before(:each) do |example|
        Sidekiq.configure_client do |config|
          config.redis = { url: redis_url }
        end
        reset_sidekiq_middlewares
        redis.flushdb
      end

      specify do
        event = TimestampEnrichment.with_timestamp(Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"), Time.utc(2019, 9, 30))
        serialized_event = RubyEventStore::Mappers::Default.new.event_to_serialized_record(event)
        class ::CorrectAsyncHandler
          include Sidekiq::Worker
          def through_outbox?; true; end
        end

        SidekiqScheduler.new.call(CorrectAsyncHandler, serialized_event)
        consumer = Consumer.new(default_options, logger: test_logger)
        consumer.one_loop
        entry_from_outbox = JSON.parse(redis.lindex("queue:default", 0))

        CorrectAsyncHandler.perform_async(serialized_event.to_h)
        entry_from_sidekiq = JSON.parse(redis.lindex("queue:default", 0))

        expect(redis.llen("queue:default")).to eq(2)
        expect(entry_from_outbox.keys).to eq(entry_from_sidekiq.keys)
        expect(entry_from_outbox.except("created_at", "enqueued_at", "jid")).to eq(entry_from_sidekiq.except("created_at", "enqueued_at", "jid"))
        expect(entry_from_outbox.fetch("jid")).not_to eq(entry_from_sidekiq.fetch("jid"))
      end
    end
  end
end
