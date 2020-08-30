require 'spec_helper'

module RubyEventStore
  module Outbox
    RSpec.describe Consumer, db: true do
      include SchemaHelper

      let(:redis_url) { ENV["REDIS_URL"] }
      let(:database_url) { ENV["DATABASE_URL"] }
      let(:redis) { Redis.new(url: redis_url) }
      let(:logger_output) { StringIO.new }
      let(:logger) { Logger.new(logger_output) }
      let(:default_configuration) { Consumer::Configuration.new(database_url: database_url, redis_url: redis_url, split_keys: ["default", "default2"], message_format: SIDEKIQ5_FORMAT, batch_size: 100) }
      let(:metrics) { Metrics::Null.new }

      before(:each) do
        redis.flushdb
      end

      specify "updates enqueued_at" do
        record = create_record("default", "default")
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)

        consumer.one_loop

        record.reload
        expect(record.enqueued_at).to be_present
      end

      specify "push the jobs to sidekiq" do
        record = create_record("default", "default")
        clock = TickingClock.new
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, clock: clock, logger: logger, metrics: metrics)
        result = consumer.one_loop

        record.reload
        expect(redis.llen("queue:default")).to eq(1)
        payload_in_redis = JSON.parse(redis.lindex("queue:default", 0))
        expect(payload_in_redis).to include(JSON.parse(record.payload))
        expect(payload_in_redis["enqueued_at"]).to eq(clock.tick(1).to_f)
        expect(record.enqueued_at).to eq(clock.tick(1))
        expect(result).to eq(true)
        expect(logger_output.string).to include("Sent 1 messages from outbox table")
      end

      specify "push multiple jobs to different queues" do
        record1 = create_record("default", "default")
        record2 = create_record("default", "default")
        record3 = create_record("default2", "default2")
        clock = TickingClock.new
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, clock: clock, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(redis.llen("queue:default")).to eq(2)
        expect(redis.llen("queue:default2")).to eq(1)
      end

      specify "sidekiq processor ensures that used queues do exist" do
        create_record("queue", "default")
        create_record("queue2", "default2")
        create_record("other_queue", "other_split")
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)

        consumer.one_loop

        expect(redis.scard("queues")).to eq(2)
        expect(redis.smembers("queues")).to match_array(["queue", "queue2"])
      end

      specify "init logs" do
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)
        consumer.init

        expect(logger_output.string).to include("Initiated RubyEventStore::Outbox v#{RubyEventStore::Outbox::VERSION}")
      end

      specify "returns false if no records" do
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(result).to eq(false)
      end

      specify "returns false if didnt aquire lock" do
        record = create_record("default", "default")
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)
        clock = TickingClock.new
        Lock.obtain(FetchSpecification.new(SIDEKIQ5_FORMAT, "default"), "some-other-process-uuid", clock: clock)

        result = consumer.one_loop

        expect(result).to eq(false)
        expect(redis.llen("queue:default")).to eq(0)
      end

      specify "already processed should be ignored" do
        record = create_record("default", "default")
        record.update!(enqueued_at: Time.now.utc)
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(result).to eq(false)
        expect(redis.llen("queue:default")).to eq(0)
        expect(logger_output.string).to be_empty
      end

      specify "other format should be ignored" do
        record = create_record("default", "default", format: "some_unknown_format")
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(result).to eq(false)
        expect(redis.llen("queue:default")).to eq(0)
        expect(logger_output.string).to be_empty
      end

      specify "records from other split keys should be ignored" do
        record = create_record("other_one", "other_one")
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(result).to eq(false)
        expect(redis.llen("queue:other_one")).to eq(0)
        expect(logger_output.string).to be_empty
      end

      xspecify "all split keys should be taken if split_keys is nil" do
        payload = {
          class: "SomeAsyncHandler",
          queue: "default",
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
        record = Record.create!(
          split_key: "default",
          created_at: Time.now.utc,
          format: "sidekiq5",
          enqueued_at: nil,
          payload: payload.to_json,
        )
        consumer = Consumer.new(SecureRandom.uuid, default_configuration.with(split_keys: nil), logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(result).to eq(true)
        expect(redis.llen("queue:default")).to eq(1)
      end

      specify "#run wait if nothing was changed" do
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)
        expect(consumer).to receive(:one_loop).and_return(false).ordered
        expect(consumer).to receive(:one_loop).and_raise("End infinite loop").ordered
        allow(consumer).to receive(:sleep)

        expect do
          consumer.run
        end.to raise_error("End infinite loop")

        expect(consumer).to have_received(:sleep).with(0.5)
      end

      specify "#run doesnt wait if something changed" do
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)
        expect(consumer).to receive(:one_loop).and_return(true).ordered
        expect(consumer).to receive(:one_loop).and_raise("End infinite loop").ordered
        allow(consumer).to receive(:sleep)

        expect do
          consumer.run
        end.to raise_error("End infinite loop")

        expect(consumer).not_to have_received(:sleep)
      end

      specify "incorrect payload wont cause later messages to schedule" do
        record1 = create_record("default", "default")
        record1.update!(payload: "unparsable garbage")
        record2 = create_record("default", "default")
        clock = TickingClock.new
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, clock: clock, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(result).to eq(true)
        expect(record1.reload.enqueued_at).to be_nil
        expect(record2.reload.enqueued_at).to be_present
        expect(redis.llen("queue:default")).to eq(1)
        expect(logger_output.string).to include("JSON::ParserError")
      end

      specify "deadlock when obtaining lock just skip that attempt" do
        expect(Lock).to receive(:lock).and_raise(ActiveRecord::Deadlocked)
        clock = TickingClock.new
        consumer = Consumer.new(SecureRandom.uuid, default_configuration.with(split_keys: ["default"]), clock: clock, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(logger_output.string).to match(/Obtaining lock .* failed \(deadlock\)/)
        expect(result).to eq(false)
        expect(redis.llen("queue:default")).to eq(0)
      end

      specify "lock timeout when obtaining lock just skip that attempt" do
        expect(Lock).to receive(:lock).and_raise(ActiveRecord::LockWaitTimeout)
        clock = TickingClock.new
        consumer = Consumer.new(SecureRandom.uuid, default_configuration.with(split_keys: ["default"]), clock: clock, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(logger_output.string).to match(/Obtaining lock .* failed \(lock timeout\)/)
        expect(result).to eq(false)
        expect(redis.llen("queue:default")).to eq(0)
      end

      specify "obtaining taken lock just skip that attempt" do
        clock = TickingClock.new
        Lock.obtain(FetchSpecification.new(SIDEKIQ5_FORMAT, "default"), "other-process-uuid", clock: clock)
        consumer = Consumer.new(SecureRandom.uuid, default_configuration.with(split_keys: ["default"]), clock: clock, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(logger_output.string).to match(/Obtaining lock .* unsuccessful \(taken\)/)
        expect(result).to eq(false)
        expect(redis.llen("queue:default")).to eq(0)
      end

      specify "deadlock when releasing lock doesnt do anything" do
        record = create_record("default", "default")
        allow(Lock).to receive(:lock).and_wrap_original do |m, *args|
          if caller.any? {|l| l.include? "`release'"}
            raise ActiveRecord::Deadlocked
          else
            m.call(*args)
          end
        end
        clock = TickingClock.new
        consumer = Consumer.new(SecureRandom.uuid, default_configuration.with(split_keys: ["default"]), clock: clock, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(logger_output.string).to match(/Releasing lock .* failed \(deadlock\)/)
        expect(result).to eq(true)
        expect(redis.llen("queue:default")).to eq(1)
      end

      specify "lock timeout when releasing lock doesnt do anything" do
        record = create_record("default", "default")
        allow(Lock).to receive(:lock).and_wrap_original do |m, *args|
          if caller.any? {|l| l.include? "`release'"}
            raise ActiveRecord::LockWaitTimeout
          else
            m.call(*args)
          end
        end
        clock = TickingClock.new
        consumer = Consumer.new(SecureRandom.uuid, default_configuration.with(split_keys: ["default"]), clock: clock, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(logger_output.string).to match(/Releasing lock .* failed \(lock timeout\)/)
        expect(result).to eq(true)
        expect(redis.llen("queue:default")).to eq(1)
      end

      specify "after successful loop, lock is released" do
        record = create_record("default", "default")
        clock = TickingClock.new
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, clock: clock, logger: logger, metrics: metrics)

        result = consumer.one_loop

        lock = Lock.find_by!(split_key: "default")
        expect(lock.locked_by).to be_nil
        expect(lock.locked_at).to be_nil
      end

      specify "lock disappearing in the meantime, doesnt do anything" do
        record = create_record("default", "default")
        clock = TickingClock.new
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, clock: clock, logger: logger, metrics: metrics)
        allow(consumer).to receive(:release_lock_for_process).and_wrap_original do |m, *args|
          Lock.delete_all
          m.call(*args)
        end

        result = consumer.one_loop

        expect(logger_output.string).to match(/Releasing lock .* failed \(not taken by this process\)/)
        expect(result).to eq(true)
        expect(redis.llen("queue:default")).to eq(1)
      end

      specify "lock stolen in the meantime, doesnt do anything" do
        record = create_record("default", "default")
        clock = TickingClock.new
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, clock: clock, logger: logger, metrics: metrics)
        allow(consumer).to receive(:release_lock_for_process).and_wrap_original do |m, *args|
          Lock.update_all(locked_by: SecureRandom.uuid)
          m.call(*args)
        end

        result = consumer.one_loop

        expect(logger_output.string).to match(/Releasing lock .* failed \(not taken by this process\)/)
        expect(result).to eq(true)
        expect(redis.llen("queue:default")).to eq(1)
      end

      specify "old lock can be reobtained" do
        Lock.obtain(FetchSpecification.new(SIDEKIQ5_FORMAT, "default"), "some-old-uuid", clock: TickingClock.new(start: 10.minutes.ago))
        record = create_record("default", "default")
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(result).to eq(true)
        expect(redis.llen("queue:default")).to eq(1)
        expect(record.reload.enqueued_at).to be_present
      end

      specify "relatively fresh locks are not reobtained" do
        Lock.obtain(FetchSpecification.new(SIDEKIQ5_FORMAT, "default"), "some-old-uuid", clock: TickingClock.new(start: 9.minutes.ago))
        create_record("default", "default")
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(result).to eq(false)
      end

      specify "when inserting lock, other process may do same concurrently" do
        record = create_record("default", "default")
        clock = TickingClock.new
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, clock: clock, logger: logger, metrics: metrics)
        allow(Lock).to receive(:create!).and_wrap_original do |m, *args|
          m.call(*args) # To simulate someone inserting a record just before us
          m.call(*args)
        end

        result = consumer.one_loop

        expect(result).to eq(true)
        expect(redis.llen("queue:default")).to eq(1)
        expect(record.reload.enqueued_at).to be_present
      end

      specify "more than one loop works" do
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)
        consumer.one_loop
        record = create_record("default", "default")

        second_loop_result = consumer.one_loop

        expect(second_loop_result).to eq(true)
        expect(redis.llen("queue:default")).to eq(1)
        expect(record.reload.enqueued_at).to be_present
      end

      specify "split keys are respected" do
        consumer_with_other = Consumer.new(SecureRandom.uuid, default_configuration.with(split_keys: ["other"]), logger: logger, metrics: metrics)
        consumer_with_other.one_loop
        record = create_record("other", "other")
        consumer_without_other = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)

        result = consumer_without_other.one_loop

        expect(result).to eq(false)
        expect(record.reload.enqueued_at).to be_nil
      end

      specify "there are multiple batches in one loop" do
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)
        records = (default_configuration.batch_size + 1).times.map {|r| create_record("default", "default") }

        result = consumer.one_loop

        records.each(&:reload)
        expect(records.select {|r| r.enqueued? }.size).to eq(101)
        expect(result).to eq(true)
      end

      specify "death of a consumer shouldnt prevent other processes from processing" do
        consumer_1 = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)
        expect(Record).to receive(:where).and_raise("Unexpected error, such as OOM").ordered
        expect(Record).to receive(:where).and_call_original.ordered.at_least(2).times
        expect do
          consumer_1.one_loop
        end.to raise_error(/Unexpected error/)

        record1 = create_record("default", "default")
        record2 = create_record("default2", "default2")
        consumer_2 = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)

        result = consumer_2.one_loop

        # We don't expect both records to be processed (because one of the Locks may be obtained by crashed process, but we expect to do SOME work in ANY splits.
        expect(result).to eq(true)
        expect(Record.where("enqueued_at is not null").count).to be_positive
      end

      specify "lock is refreshed after each batch" do
        consumer = Consumer.new(SecureRandom.uuid, default_configuration, logger: logger, metrics: metrics)
        records = (default_configuration.batch_size + 1).times.map {|r| create_record("default", "default") }
        expect_any_instance_of(Lock).to receive(:refresh).twice.and_call_original

        consumer.one_loop
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
        record = Record.create!(
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
