# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Outbox
    ::RSpec.describe Consumer, db: true, redis: true do
      include SchemaHelper
      let(:redis_url) { RedisIsolation.redis_url }
      let(:database_url) { ENV["DATABASE_URL"] }
      let(:redis) { RedisClient.config(url: redis_url).new_client }
      let(:logger_output) { StringIO.new }
      let(:logger) { Logger.new(logger_output) }
      let(:null_metrics) { Metrics::Null.new }
      let(:test_metrics) { Metrics::Test.new }

      shared_examples_for "a consumer" do

        specify "updates enqueued_at" do
          record = create_record("default", "default")
          consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)

          consumer.process

          record.reload
          expect(record.enqueued_at).to be_present
        end

        specify "push the jobs to sidekiq" do
          record = create_record("default", "default")
          clock = TickingClock.new
          consumer =
            Consumer.new(SecureRandom.uuid, default_configuration, clock: clock, logger: logger, metrics: null_metrics)
          result = consumer.process

          record.reload
          expect(redis.call("LLEN", "queue:default")).to eq(1)
          payload_in_redis = JSON.parse(redis.call("LINDEX", "queue:default", 0))
          expect(payload_in_redis).to include(JSON.parse(record.payload))
          expect(payload_in_redis["enqueued_at"]).to eq(clock.tick(1).to_f)
          expect(record.enqueued_at).to eq(clock.tick(1))
          expect(result).to eq(true)
          expect(logger_output.string).to include("Sent 1 messages from outbox table")
        end

        specify "push multiple jobs to different queues" do
          create_record("default", "default")
          create_record("default", "default")
          create_record("default2", "default2")
          clock = TickingClock.new
          consumer =
            Consumer.new(SecureRandom.uuid, default_configuration, clock: clock, logger: logger, metrics: null_metrics)

          consumer.process

          expect(redis.call("LLEN", "queue:default")).to eq(2)
          expect(redis.call("LLEN", "queue:default2")).to eq(1)
        end

        specify "sidekiq processor ensures that used queues do exist" do
          create_record("queue", "default")
          create_record("queue2", "default2")
          create_record("other_queue", "other_split")
          consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)

          consumer.process

          expect(redis.call("SCARD", "queues")).to eq(2)
          expect(redis.call("SMEMBERS", "queues")).to match_array(%w[queue queue2])
        end

        specify "returns false if no records" do
          consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)

          result = consumer.process

          expect(result).to eq(false)
        end


        specify "already processed should be ignored" do
          record = create_record("default", "default")
          record.update!(enqueued_at: Time.now.utc)
          consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)

          result = consumer.process

          expect(result).to eq(false)
          expect(redis.call("LLEN", "queue:default")).to eq(0)
          expect(logger_output.string).to be_empty
        end

        specify "other format should be ignored" do
          create_record("default", "default", format: "some_unknown_format")
          consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)

          result = consumer.process

          expect(result).to eq(false)
          expect(redis.call("LLEN", "queue:default")).to eq(0)
          expect(logger_output.string).to be_empty
        end

        specify "records from other split keys should be ignored" do
          create_record("other_one", "other_one")
          consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)

          result = consumer.process

          expect(result).to eq(false)
          expect(redis.call("LLEN", "queue:other_one")).to eq(0)
          expect(logger_output.string).to be_empty
        end

        xspecify "all split keys should be taken if split_keys is nil" do
          payload = {
            class: "SomeAsyncHandler",
            queue: "default",
            created_at: Time.now.utc,
            jid: SecureRandom.hex(12),
            retry: true,
            args: [
              {
                event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
                event_type: "RubyEventStore::Event",
                data: "--- {}\n",
                metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n"
              }
            ]
          }
          Repository::Record.create!(
            split_key: "default",
            created_at: Time.now.utc,
            format: "sidekiq5",
            enqueued_at: nil,
            payload: payload.to_json
          )
          consumer =
            Consumer.new(
              SecureRandom.uuid,
              default_configuration.with(split_keys: nil),
              logger: logger,
              metrics: null_metrics
            )

          result = consumer.process

          expect(result).to eq(true)
          expect(redis.call("LLEN", "queue:default")).to eq(1)
        end

        specify "incorrect payload wont cause later messages to schedule" do
          record1 = create_record("default", "default")
          record1.update!(payload: "unparsable garbage")
          record2 = create_record("default", "default")
          clock = TickingClock.new
          consumer =
            Consumer.new(SecureRandom.uuid, default_configuration, clock: clock, logger: logger, metrics: null_metrics)

          result = consumer.process

          expect(result).to eq(true)
          expect(record1.reload.enqueued_at).to be_nil
          expect(record2.reload.enqueued_at).to be_present
          expect(redis.call("LLEN", "queue:default")).to eq(1)
          expect(logger_output.string).to include("JSON::ParserError")
        end

        specify "old lock can be reobtained" do
          Repository::Lock.obtain(
            FetchSpecification.new(SIDEKIQ5_FORMAT, "default"),
            "some-old-uuid",
            clock: TickingClock.new(start: 10.minutes.ago)
          )
          record = create_record("default", "default")
          consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)

          result = consumer.process

          expect(result).to eq(true)
          expect(redis.call("LLEN", "queue:default")).to eq(1)
          expect(record.reload.enqueued_at).to be_present
        end

        specify "when inserting lock, other process may do same concurrently" do
          record = create_record("default", "default")
          clock = TickingClock.new
          consumer =
            Consumer.new(SecureRandom.uuid, default_configuration, clock: clock, logger: logger, metrics: null_metrics)
          allow(Repository::Lock).to receive(:create!).and_wrap_original do |m, *args|
            m.call(*args) # To simulate someone inserting a record just before us
            m.call(*args)
          end

          result = consumer.process

          expect(result).to eq(true)
          expect(redis.call("LLEN", "queue:default")).to eq(1)
          expect(record.reload.enqueued_at).to be_present
        end

        specify "more than one loop works" do
          consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)
          consumer.process
          record = create_record("default", "default")

          second_loop_result = consumer.process

          expect(second_loop_result).to eq(true)
          expect(redis.call("LLEN", "queue:default")).to eq(1)
          expect(record.reload.enqueued_at).to be_present
        end

        specify "split keys are respected" do
          consumer_with_other =
            Consumer.new(
              SecureRandom.uuid,
              default_configuration.with(split_keys: ["other"]),
              logger: logger,
              metrics: null_metrics
            )
          consumer_with_other.process
          record = create_record("other", "other")
          consumer_without_other =
            Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)

          result = consumer_without_other.process

          expect(result).to eq(false)
          expect(record.reload.enqueued_at).to be_nil
        end

        specify "there are multiple batches in one loop" do
          consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)
          records = (default_configuration.batch_size + 1).times.map { |r| create_record("default", "default") }

          result = consumer.process

          records.each(&:reload)
          expect(records.select { |r| r.enqueued? }.size).to eq(101)
          expect(result).to eq(true)
        end

        specify "lock is refreshed after each batch" do
          skip "https://github.com/rspec/rspec-mocks/issues/1306" if RUBY_VERSION >= "3.0"
          consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)
          2.times.map { |r| create_record("default", "default") }
          expect_any_instance_of(Repository::Lock).to receive(:refresh).twice.and_call_original

          consumer.process
        end

        specify "clean old jobs" do
          create_record("default", "default")
          clock = TickingClock.new
          consumer =
            Consumer.new(
              SecureRandom.uuid,
              default_configuration.with(cleanup: "P7D"),
              clock: clock,
              logger: logger,
              metrics: null_metrics
            )
          consumer.process
          expect(redis.call("LLEN", "queue:default")).to eq(1)
          expect(Repository::Record.count).to eq(1)
          travel (7.days + 1.minute)

          consumer.process

          expect(Repository::Record.count).to eq(0)
        end

        specify "clean old jobs with limit" do
          3.times.map { create_record("default", "default") }
          clock = TickingClock.new
          consumer =
            Consumer.new(
              SecureRandom.uuid,
              default_configuration.with(cleanup: "P7D", cleanup_limit: 2),
              clock: clock,
              logger: logger,
              metrics: null_metrics
            )
          consumer.process
          expect(redis.call("LLEN", "queue:default")).to eq(3)
          expect(Repository::Record.count).to eq(3)
          travel (7.days + 1.minute)

          consumer.process

          expect(Repository::Record.count).to eq(1)
        end

        specify "clean old jobs - lock timeout" do
          create_record("default", "default")
          clock = TickingClock.new
          consumer =
            Consumer.new(
              SecureRandom.uuid,
              default_configuration.with(cleanup: "P7D"),
              clock: clock,
              logger: logger,
              metrics: test_metrics
            )
          consumer.process
          expect(redis.call("LLEN", "queue:default")).to eq(1)
          expect(Repository::Record.count).to eq(1)
          travel (7.days + 1.minute)

          allow_any_instance_of(::ActiveRecord::Relation).to receive(:delete_all).and_raise(::ActiveRecord::LockWaitTimeout)
          consumer.process

          expect(Repository::Record.count).to eq(1)
          expect(logger_output.string).to include("Cleanup for split_key 'default' failed (lock timeout)")
          expect(test_metrics.operation_results).to include({ operation: "cleanup", result: "lock_timeout" })
        end

        specify "clean old jobs - deadlock" do
          create_record("default", "default")
          clock = TickingClock.new
          consumer =
            Consumer.new(
              SecureRandom.uuid,
              default_configuration.with(cleanup: "P7D"),
              clock: clock,
              logger: logger,
              metrics: test_metrics
            )
          consumer.process
          expect(redis.call("LLEN", "queue:default")).to eq(1)
          expect(Repository::Record.count).to eq(1)
          travel (7.days + 1.minute)

          allow_any_instance_of(::ActiveRecord::Relation).to receive(:delete_all).and_raise(::ActiveRecord::Deadlocked)
          consumer.process

          expect(Repository::Record.count).to eq(1)
          expect(logger_output.string).to include("Cleanup for split_key 'default' failed (deadlock)")
          expect(test_metrics.operation_results).to include({ operation: "cleanup", result: "deadlocked" })
        end
      end

      context "with locking repository" do
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
        let(:repository) { :locking }
        it_behaves_like "a consumer"

        specify "deadlock when obtaining lock just skip that attempt" do
          expect(Repository::Lock).to receive(:lock).and_raise(::ActiveRecord::Deadlocked)
          clock = TickingClock.new
          consumer =
            Consumer.new(
              SecureRandom.uuid,
              default_configuration.with(split_keys: ["default"]),
              clock: clock,
              logger: logger,
              metrics: test_metrics
            )

          result = consumer.process

          expect(logger_output.string).to include("Obtaining lock for split_key 'default' failed (deadlock)")
          expect(test_metrics.operation_results).to include({ operation: "obtain", result: "deadlocked" })
          expect(result).to eq(false)
          expect(redis.call("LLEN", "queue:default")).to eq(0)
        end

        specify "lock timeout when obtaining lock just skip that attempt" do
          expect(Repository::Lock).to receive(:lock).and_raise(::ActiveRecord::LockWaitTimeout)
          clock = TickingClock.new
          consumer =
            Consumer.new(
              SecureRandom.uuid,
              default_configuration.with(split_keys: ["default"]),
              clock: clock,
              logger: logger,
              metrics: test_metrics
            )

          result = consumer.process

          expect(logger_output.string).to include("Obtaining lock for split_key 'default' failed (lock timeout)")
          expect(test_metrics.operation_results).to include({ operation: "obtain", result: "lock_timeout" })
          expect(result).to eq(false)
          expect(redis.call("LLEN", "queue:default")).to eq(0)
        end

        specify "obtaining taken lock just skip that attempt" do
          clock = TickingClock.new
          Repository::Lock.obtain(FetchSpecification.new(SIDEKIQ5_FORMAT, "default"), "other-process-uuid", clock: clock)
          consumer =
            Consumer.new(
              SecureRandom.uuid,
              default_configuration.with(split_keys: ["default"]),
              clock: clock,
              logger: logger,
              metrics: test_metrics
            )

          result = consumer.process

          expect(logger_output.string).to include("Obtaining lock for split_key 'default' unsuccessful (taken)")
          expect(test_metrics.operation_results).to include({ operation: "obtain", result: "taken" })
          expect(result).to eq(false)
          expect(redis.call("LLEN", "queue:default")).to eq(0)
        end

        specify "deadlock when releasing lock doesnt do anything" do
          create_record("default", "default")
          allow(Repository::Lock).to receive(:lock).and_wrap_original do |m, *args|
            if caller.any? do |l|
              l.include?("in `release'") || # Ruby < 3.4
                l.include?("in 'RubyEventStore::Outbox::Repository::Lock.release'") # Ruby 3.4+
            end
              raise ::ActiveRecord::Deadlocked
            else
              m.call(*args)
            end
          end
          clock = TickingClock.new
          consumer =
            Consumer.new(
              SecureRandom.uuid,
              default_configuration.with(split_keys: ["default"]),
              clock: clock,
              logger: logger,
              metrics: test_metrics
            )

          result = consumer.process

          expect(logger_output.string).to include("Releasing lock for split_key 'default' failed \(deadlock\)")
          expect(test_metrics.operation_results).to include({ operation: "release", result: "deadlocked" })
          expect(result).to eq(true)
          expect(redis.call("LLEN", "queue:default")).to eq(1)
        end

        specify "lock timeout when releasing lock doesnt do anything" do
          create_record("default", "default")
          allow(Repository::Lock).to receive(:lock).and_wrap_original do |m, *args|
            if caller.any? do |l|
              l.include?("in `release'") || # Ruby < 3.4
                l.include?("in 'RubyEventStore::Outbox::Repository::Lock.release'") # Ruby 3.4+
            end
              raise ::ActiveRecord::LockWaitTimeout
            else
              m.call(*args)
            end
          end
          clock = TickingClock.new
          consumer =
            Consumer.new(
              SecureRandom.uuid,
              default_configuration.with(split_keys: ["default"]),
              clock: clock,
              logger: logger,
              metrics: test_metrics
            )

          result = consumer.process

          expect(logger_output.string).to include("Releasing lock for split_key 'default' failed (lock timeout)")
          expect(test_metrics.operation_results).to include({ operation: "release", result: "lock_timeout" })
          expect(result).to eq(true)
          expect(redis.call("LLEN", "queue:default")).to eq(1)
        end

        specify "after successful loop, lock is released" do
          create_record("default", "default")
          clock = TickingClock.new
          consumer =
            Consumer.new(SecureRandom.uuid, default_configuration, clock: clock, logger: logger, metrics: null_metrics)

          consumer.process

          lock = Repository::Lock.find_by!(split_key: "default")
          expect(lock.locked_by).to be_nil
          expect(lock.locked_at).to be_nil
        end

        specify "lock disappearing in the meantime, doesnt do anything" do
          create_record("default", "default")
          clock = TickingClock.new
          consumer =
            Consumer.new(SecureRandom.uuid, default_configuration, clock: clock, logger: logger, metrics: test_metrics)
          allow(consumer).to receive(:release_lock_for_process).and_wrap_original do |m, *args|
            Repository::Lock.delete_all
            m.call(*args)
          end

          result = consumer.process

          expect(logger_output.string).to include(
            "Releasing lock for split_key 'default' failed (not taken by this process)"
          )
          expect(test_metrics.operation_results).to include({ operation: "release", result: "not_taken_by_this_process" })
          expect(result).to eq(true)
          expect(redis.call("LLEN", "queue:default")).to eq(1)
        end

        specify "lock stolen in the meantime, doesnt do anything" do
          create_record("default", "default")
          clock = TickingClock.new
          consumer =
            Consumer.new(SecureRandom.uuid, default_configuration, clock: clock, logger: logger, metrics: null_metrics)
          allow(consumer).to receive(:release_lock_for_process).and_wrap_original do |m, *args|
            Repository::Lock.update_all(locked_by: SecureRandom.uuid)
            m.call(*args)
          end

          result = consumer.process

          expect(logger_output.string).to match(/Releasing lock .* failed \(not taken by this process\)/)
          expect(result).to eq(true)
          expect(redis.call("LLEN", "queue:default")).to eq(1)
        end

        specify "relatively fresh locks are not reobtained" do
          Repository::Lock.obtain(
            FetchSpecification.new(SIDEKIQ5_FORMAT, "default"),
            "some-old-uuid",
            clock: TickingClock.new(start: 9.minutes.ago)
          )
          create_record("default", "default")
          consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)

          result = consumer.process

          expect(result).to eq(false)
        end

        specify "returns false if didnt aquire lock" do
          create_record("default", "default")
          consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)
          clock = TickingClock.new
          Repository::Lock.obtain(
            FetchSpecification.new(SIDEKIQ5_FORMAT, "default"),
            "some-other-process-uuid",
            clock: clock
          )

          result = consumer.process

          expect(result).to eq(false)
          expect(redis.call("LLEN", "queue:default")).to eq(0)
        end

        specify "death of a consumer shouldnt prevent other processes from processing" do
          consumer_1 = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)
          expect(Repository::Record).to receive(:where).and_raise("Unexpected error, such as OOM").ordered
          expect(Repository::Record).to receive(:where).and_call_original.ordered.at_least(2).times
          expect { consumer_1.process }.to raise_error(/Unexpected error/)

          create_record("default", "default")
          create_record("default2", "default2")
          consumer_2 = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)

          result = consumer_2.process

          # We don't expect both records to be processed (because one of the Locks may be obtained by crashed process, but we expect to do SOME work in ANY splits.
          expect(result).to eq(true)
          expect(Repository::Record.where("enqueued_at is not null").count).to be_positive
        end

      end

      context "with non-locking repository" do
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
        let(:repository) { :non_locking }

        if ENV["DATABASE_URL"].to_s =~ /sqlite/
          specify "does not support non-locking repository with SQLite3 adapter" do
            expect { Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics) }
              .to raise_error(/sqlite does not support SKIP LOCKED/)
          end
        else
          it_behaves_like "a consumer"

          specify "consumers are non-locking and don't need to wait for a lock when other processes are locking some records" do
            consumer_1 = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)
            expect(consumer_1).to receive(:retrieve_batch).and_raise("Unexpected error, such as OOM").ordered
            expect { consumer_1.process }.to raise_error(/Unexpected error/)

            create_record("default", "default")
            create_record("default2", "default2")
            consumer_2 = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: null_metrics)

            result = consumer_2.process

            # We don't expect both records to be processed (because one of the Locks may be obtained by crashed process, but we expect to do SOME work in ANY splits.
            expect(result).to eq(true)
            expect(Repository::Record.where("enqueued_at is not null").count).to be_positive
          end

        end

      end

      def create_record(queue, split_key, format: "sidekiq5")
        payload = {
          class: "SomeAsyncHandler",
          queue: queue,
          created_at: Time.now.utc,
          jid: SecureRandom.hex(12),
          retry: true,
          args: [
            {
              event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
              event_type: "RubyEventStore::Event",
              data: "--- {}\n",
              metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n"
            }
          ]
        }
        Repository::Record.create!(
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
