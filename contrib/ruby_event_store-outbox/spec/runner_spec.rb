# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Outbox
    ::RSpec.describe Consumer, db: true, redis: true do
      include SchemaHelper

      shared_examples_for "a runner" do
        let(:redis_url) { RedisIsolation.redis_url }
        let(:database_url) { ENV["DATABASE_URL"] }
        let(:redis) { RedisClient.config(url: redis_url).new_client }
        let(:logger_output) { StringIO.new }
        let(:logger) { Logger.new(logger_output) }
        let(:default_configuration) do
          Configuration.new(
            database_url: database_url,
            redis_url: redis_url,
            split_keys: %w[default default2],
            message_format: SIDEKIQ5_FORMAT,
            batch_size: 100,
            cleanup: :none,
            cleanup_limit: :all,
            sleep_on_empty: 1,
            repository: repository
          )
        end
        let(:null_metrics) { Metrics::Null.new }

        specify "#run wait if nothing was changed" do
          consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)
          runner = Runner.new(consumer, default_configuration, logger: logger)
          expect(consumer).to receive(:process).and_return(false).ordered
          expect(consumer).to receive(:process).and_raise("End infinite loop").ordered
          allow(runner).to receive(:sleep)

          expect { runner.run }.to raise_error("End infinite loop")

          expect(runner).to have_received(:sleep).with(1)
        end

        specify "#run doesnt wait if something changed" do
          consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)
          runner = Runner.new(consumer, default_configuration, logger: logger)
          expect(consumer).to receive(:process).and_return(true).ordered
          expect(consumer).to receive(:process).and_raise("End infinite loop").ordered
          allow(runner).to receive(:sleep)

          expect { runner.run }.to raise_error("End infinite loop")

          expect(runner).not_to have_received(:sleep)
        end

        specify "init logs" do
          consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)
          runner = Runner.new(consumer, default_configuration, logger: logger)
          expect(consumer).to receive(:process).and_raise("End infinite loop")

          expect { runner.run }.to raise_error("End infinite loop")

          expect(logger_output.string).to include("Initiated RubyEventStore::Outbox v#{VERSION}")
        end
      end

      context "with locking repository" do
        let(:repository) { :locking }
        it_behaves_like "a runner"
      end

      unless ENV["DATABASE_URL"].to_s =~ /sqlite/
        context "with non-locking repository" do
          let(:repository) { :non_locking }
          it_behaves_like "a runner"
        end
      end
    end
  end
end
