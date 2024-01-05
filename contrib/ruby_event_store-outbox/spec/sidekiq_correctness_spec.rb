# frozen_string_literal: true

require "spec_helper"
require_relative "./support/sidekiq"

module RubyEventStore
  module Outbox
    ::RSpec.describe "Sidekiq correctness spec", db: true do
      include SchemaHelper
      let(:redis_url) { RedisIsolation.redis_url }
      let(:database_url) { ENV["DATABASE_URL"] }
      let(:redis) { Redis.new(url: redis_url) }
      let(:test_logger) { Logger.new(StringIO.new) }
      let(:default_configuration) do
        Configuration.new(
          database_url: database_url,
          redis_url: redis_url,
          split_keys: ["default"],
          message_format: SIDEKIQ5_FORMAT,
          batch_size: 100,
          cleanup: :none,
          cleanup_limit: :all,
          sleep_on_empty: 1
        )
      end
      let(:metrics) { Metrics::Null.new }

      before(:each) do |example|
        Sidekiq.configure_client { |config| config.redis = { url: redis_url } }
        reset_sidekiq_middlewares
        redis.flushdb
      end

      specify do
        event =
          TimeEnrichment.with(
            Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"),
            timestamp: Time.utc(2019, 9, 30)
          )
        event_record = Mappers::Default.new.event_to_record(event)
        class ::CorrectAsyncHandler
          include Sidekiq::Worker
          def through_outbox?
            true
          end
        end

        SidekiqScheduler.new.call(CorrectAsyncHandler, event_record)
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: test_logger, metrics: metrics)
        consumer.process
        entry_from_outbox = JSON.parse(redis.lindex("queue:default", 0))

        CorrectAsyncHandler.perform_async(event_record.serialize(Serializers::YAML).to_h.transform_keys(&:to_s))
        entry_from_sidekiq = JSON.parse(redis.lindex("queue:default", 0))

        expect(redis.llen("queue:default")).to eq(2)
        expect(entry_from_outbox.keys.sort).to eq(entry_from_sidekiq.keys.sort)
        expect(entry_from_outbox.except("created_at", "enqueued_at", "jid")).to eq(
          entry_from_sidekiq.except("created_at", "enqueued_at", "jid")
        )
        expect(entry_from_outbox.fetch("jid")).not_to eq(entry_from_sidekiq.fetch("jid"))
      end

      specify "Redis::TimeoutError is retriable" do
        stub_const("RubyEventStore::Outbox::Consumer::MAXIMUM_BATCH_FETCHES_IN_ONE_LOCK", 1)
        event =
          TimeEnrichment.with(
            Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"),
            timestamp: Time.utc(2019, 9, 30)
          )
        event_record = Mappers::Default.new.event_to_record(event)
        class ::CorrectAsyncHandler
          include Sidekiq::Worker
          def through_outbox?
            true
          end
        end

        SidekiqScheduler.new.call(CorrectAsyncHandler, event_record)
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: test_logger, metrics: metrics)
        failed_once = false
        allow_any_instance_of(Redis).to receive(:lpush).and_wrap_original do |m, *args|
          if failed_once
            m.call(*args)
          else
            failed_once = true
            raise Redis::TimeoutError
          end
        end
        consumer.process
        entry_from_outbox = redis.lindex("queue:default", 0)

        expect(entry_from_outbox).to be_present
      end

      specify "Redis::ConnectionError is retriable" do
        stub_const("RubyEventStore::Outbox::Consumer::MAXIMUM_BATCH_FETCHES_IN_ONE_LOCK", 1)
        event =
          TimeEnrichment.with(
            Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"),
            timestamp: Time.utc(2019, 9, 30)
          )
        event_record = Mappers::Default.new.event_to_record(event)
        class ::CorrectAsyncHandler
          include Sidekiq::Worker
          def through_outbox?
            true
          end
        end

        SidekiqScheduler.new.call(CorrectAsyncHandler, event_record)
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: test_logger, metrics: metrics)
        failed_once = false
        allow_any_instance_of(Redis).to receive(:lpush).and_wrap_original do |m, *args|
          if failed_once
            m.call(*args)
          else
            failed_once = true
            raise Redis::ConnectionError
          end
        end
        consumer.process
        entry_from_outbox = redis.lindex("queue:default", 0)

        expect(entry_from_outbox).to be_present
      end
    end
  end
end
