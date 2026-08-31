# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/scheduler_lint"

module RailsEventStore
  ::RSpec.describe ActiveJobBulkScheduler do
    around { |example| ActiveJob::Base.with(logger: nil, queue_adapter: :test) { example.run } }

    it_behaves_like "scheduler", ActiveJobBulkScheduler.new(serializer: RubyEventStore::Serializers::YAML)
    it_behaves_like "scheduler", ActiveJobBulkScheduler.new(serializer: RubyEventStore::NULL)
    it_behaves_like "scheduler", ActiveJobBulkScheduler.new(serializer: JSON)

    let(:scheduler) { ActiveJobBulkScheduler.new(serializer: RubyEventStore::Serializers::YAML) }

    let(:event) do
      TimeEnrichment.with(
        RubyEventStore::Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"),
        timestamp: Time.utc(2026, 8, 25),
      )
    end
    let(:other_event) do
      TimeEnrichment.with(
        RubyEventStore::Event.new(event_id: "d39cb65f-bc3c-4fbb-9c48-1a6e16c0e2eb"),
        timestamp: Time.utc(2026, 8, 25),
      )
    end
    let(:record) { RubyEventStore::Mappers::Default.new.event_to_record(event) }
    let(:other_record) { RubyEventStore::Mappers::Default.new.event_to_record(other_event) }

    def enqueued_jobs
      ActiveJob::Base.queue_adapter.enqueued_jobs
    end

    def serialized_event(event)
      timestamp = event.metadata[:timestamp].iso8601(RubyEventStore::TIMESTAMP_PRECISION)

      {
        "event_id" => event.event_id,
        "event_type" => "RubyEventStore::Event",
        "data" => "--- {}\n",
        "metadata" => "--- {}\n",
        "timestamp" => timestamp,
        "valid_at" => timestamp,
        "_aj_symbol_keys" => [],
      }
    end

    describe "#call" do
      specify "buffers instead of enqueuing" do
        scheduler.call(MyBulkAsyncHandler, record)

        expect(enqueued_jobs).to be_empty
      end

      specify "serializes the record the same way ActiveJobScheduler does" do
        scheduler.call(MyBulkAsyncHandler, record)
        scheduler.flush

        expect(enqueued_jobs).to match(
          [hash_including(job: MyBulkAsyncHandler, args: [serialized_event(event)], queue: "default")],
        )
      end

      specify "keeps buffers of separate scheduler instances apart" do
        other_scheduler = ActiveJobBulkScheduler.new(serializer: RubyEventStore::Serializers::YAML)

        scheduler.call(MyBulkAsyncHandler, record)
        other_scheduler.call(MyBulkAsyncHandler, other_record)
        scheduler.flush

        expect(enqueued_jobs.map { |job| job[:args].first["event_id"] }).to eq([event.event_id])
      end

      specify "enqueues an ActiveJob::ConfiguredJob on its own, as perform_all_later cannot carry its options" do
        scheduler.call(MyBulkAsyncHandler.set(queue: "specific"), record)

        expect(enqueued_jobs).to match(
          [hash_including(job: MyBulkAsyncHandler, args: [serialized_event(event)], queue: "specific")],
        )
      end

      specify "flushes the buffer before an ActiveJob::ConfiguredJob, so it does not overtake it" do
        scheduler.call(MyBulkAsyncHandler, record)
        scheduler.call(MyBulkAsyncHandler.set(queue: "specific"), other_record)

        expect(enqueued_jobs).to match(
          [
            hash_including(job: MyBulkAsyncHandler, args: [serialized_event(event)], queue: "default"),
            hash_including(job: MyBulkAsyncHandler, args: [serialized_event(other_event)], queue: "specific"),
          ],
        )
      end
    end

    describe "#flush" do
      specify "enqueues everything buffered with a single perform_all_later" do
        expect(ActiveJob).to receive(:perform_all_later).once.and_call_original

        scheduler.call(MyBulkAsyncHandler, record)
        scheduler.call(MyBulkAsyncHandler, other_record)
        scheduler.flush

        expect(enqueued_jobs.map { |job| job[:args].first["event_id"] }).to eq([event.event_id, other_event.event_id])
      end

      specify "does nothing when there is nothing buffered" do
        expect(ActiveJob).not_to receive(:perform_all_later)

        scheduler.flush

        expect(enqueued_jobs).to be_empty
      end

      specify "is idempotent" do
        scheduler.call(MyBulkAsyncHandler, record)
        scheduler.flush
        scheduler.flush

        expect(enqueued_jobs.size).to eq(1)
      end

      context "driven by AfterCommitDispatcher" do
        let(:dispatcher) { AfterCommitDispatcher.new(scheduler: scheduler) }

        specify "enqueues a whole transaction with a single perform_all_later" do
          expect(ActiveJob).to receive(:perform_all_later).once.and_call_original

          ActiveRecord::Base.transaction do
            dispatcher.call(MyBulkAsyncHandler, event, record)
            dispatcher.call(MyBulkAsyncHandler, other_event, other_record)
            expect(enqueued_jobs).to be_empty
          end

          expect(enqueued_jobs.map { |job| job[:args].first["event_id"] }).to eq([event.event_id, other_event.event_id])
        end

        specify "enqueues nothing when the transaction is rolled back" do
          ActiveRecord::Base.transaction do
            dispatcher.call(MyBulkAsyncHandler, event, record)
            raise ::ActiveRecord::Rollback
          end

          expect(enqueued_jobs).to be_empty
        end

        specify "enqueues immediately when no transaction is open" do
          dispatcher.call(MyBulkAsyncHandler, event, record)

          expect(enqueued_jobs.size).to eq(1)
        end
      end
    end

    describe "#verify" do
      specify "accepts an ActiveJob class" do
        expect(scheduler.verify(MyBulkAsyncHandler)).to be(true)
      end

      specify "accepts an ActiveJob::ConfiguredJob" do
        expect(scheduler.verify(MyBulkAsyncHandler.set(queue: "specific"))).to be(true)
      end

      specify "rejects a class that is not an ActiveJob" do
        expect(scheduler.verify(Class.new)).to be(false)
      end

      specify "rejects ActiveJob::Base itself" do
        expect(scheduler.verify(ActiveJob::Base)).to be(false)
      end

      specify "rejects an arbitrary object" do
        expect(scheduler.verify(Object.new)).to be(false)
      end
    end

    describe "#initialize" do
      def with_active_job_version(version)
        allow(ActiveJob).to receive(:gem_version).and_return(Gem::Version.new(version))
      end

      specify "accepts the ActiveJob version in use" do
        expect { ActiveJobBulkScheduler.new(serializer: RubyEventStore::Serializers::YAML) }.not_to raise_error
      end

      specify "hands the serializer over to ActiveJobScheduler" do
        bulk_scheduler = ActiveJobBulkScheduler.new(serializer: JSON)

        bulk_scheduler.call(MyBulkAsyncHandler, record)
        bulk_scheduler.flush

        expect(enqueued_jobs.dig(0, :args, 0)).to include("data" => "{}")
      end

      specify "accepts the very version that introduced Transaction#after_commit" do
        with_active_job_version("7.2.0")

        expect { ActiveJobBulkScheduler.new(serializer: RubyEventStore::Serializers::YAML) }.not_to raise_error
      end

      specify "rejects a Rails that has perform_all_later but no Transaction#after_commit" do
        with_active_job_version("7.1.5")

        expect { ActiveJobBulkScheduler.new(serializer: RubyEventStore::Serializers::YAML) }.to raise_error(
          "RailsEventStore::ActiveJobBulkScheduler requires Rails 7.2 or newer",
        )
      end
    end

    class MyBulkAsyncHandler < ActiveJob::Base
      def perform(event)
      end
    end
  end
end
