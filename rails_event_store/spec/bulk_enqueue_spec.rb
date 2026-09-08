# frozen_string_literal: true

require "spec_helper"

module RailsEventStore
  ::RSpec.describe BulkEnqueue do
    around { |example| ActiveJob::Base.with(logger: nil, queue_adapter: :test) { example.run } }

    let(:scheduler) { ActiveJobBulkScheduler.new(serializer: RubyEventStore::Serializers::YAML) }

    let(:event) { TimeEnrichment.with(RubyEventStore::Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8")) }
    let(:other_event) do
      TimeEnrichment.with(RubyEventStore::Event.new(event_id: "d39cb65f-bc3c-4fbb-9c48-1a6e16c0e2eb"))
    end
    let(:record) { RubyEventStore::Mappers::Default.new.event_to_record(event) }
    let(:other_record) { RubyEventStore::Mappers::Default.new.event_to_record(other_event) }

    def enqueued_jobs
      ActiveJob::Base.queue_adapter.enqueued_jobs
    end

    def enqueued_event_ids
      enqueued_jobs.map { |job| job[:args].first["event_id"] }
    end

    describe "#call" do
      specify "buffers instead of enqueuing" do
        scheduler.call(MyBulkEnqueueHandler, record)

        expect(enqueued_jobs).to be_empty
      end

      specify "enqueues an ActiveJob::ConfiguredJob on its own, as perform_all_later cannot carry its options" do
        scheduler.call(MyBulkEnqueueHandler.set(queue: "specific"), record)

        expect(enqueued_jobs).to match([hash_including(job: MyBulkEnqueueHandler, queue: "specific")])
      end

      specify "flushes the buffer before an ActiveJob::ConfiguredJob, so it does not overtake it" do
        scheduler.call(MyBulkEnqueueHandler, record)
        scheduler.call(MyBulkEnqueueHandler.set(queue: "specific"), other_record)

        expect(enqueued_jobs).to match(
          [
            hash_including(job: MyBulkEnqueueHandler, queue: "default"),
            hash_including(job: MyBulkEnqueueHandler, queue: "specific"),
          ],
        )
        expect(enqueued_event_ids).to eq([event.event_id, other_event.event_id])
      end

      specify "builds the payload the way the scheduler it is mixed into does" do
        bulk_scheduler = ActiveJobBulkScheduler.new(serializer: JSON)

        bulk_scheduler.call(MyBulkEnqueueHandler, record)
        bulk_scheduler.flush

        expect(enqueued_jobs.dig(0, :args, 0)).to include("data" => "{}")
      end

      specify "mixes into a scheduler that takes no arguments" do
        id_only_scheduler = ActiveJobIdOnlyBulkScheduler.new

        id_only_scheduler.call(MyBulkEnqueueHandler, record)
        id_only_scheduler.flush

        expect(enqueued_jobs.dig(0, :args, 0)).to include("event_id" => event.event_id)
      end
    end

    describe "#ship" do
      specify "enqueues everything buffered with a single perform_all_later" do
        expect(ActiveJob).to receive(:perform_all_later).once.and_call_original

        scheduler.call(MyBulkEnqueueHandler, record)
        scheduler.call(MyBulkEnqueueHandler, other_record)
        scheduler.flush

        expect(enqueued_event_ids).to eq([event.event_id, other_event.event_id])
      end

      context "driven by AfterCommitDispatcher" do
        let(:dispatcher) { AfterCommitDispatcher.new(scheduler: scheduler) }

        specify "enqueues a whole transaction with a single perform_all_later" do
          expect(ActiveJob).to receive(:perform_all_later).once.and_call_original

          ActiveRecord::Base.transaction do
            dispatcher.call(MyBulkEnqueueHandler, event, record)
            dispatcher.call(MyBulkEnqueueHandler, other_event, other_record)
            expect(enqueued_jobs).to be_empty
          end

          expect(enqueued_event_ids).to eq([event.event_id, other_event.event_id])
        end

        specify "enqueues nothing when the transaction is rolled back" do
          ActiveRecord::Base.transaction do
            dispatcher.call(MyBulkEnqueueHandler, event, record)
            raise ::ActiveRecord::Rollback
          end

          expect(enqueued_jobs).to be_empty
        end

        specify "enqueues immediately when no transaction is open" do
          dispatcher.call(MyBulkEnqueueHandler, event, record)

          expect(enqueued_jobs.size).to eq(1)
        end

        specify "enqueues handlers opted into ActiveJob's own after-commit enqueuing" do
          # Rails only wires this in through a railtie, and the flag is tri-state
          # before 8.0. Handlers left at the default are unaffected by the include.
          original = MyBulkEnqueueHandler.enqueue_after_transaction_commit
          ActiveJob::Base.include(ActiveJob::EnqueueAfterTransactionCommit)
          MyBulkEnqueueHandler.enqueue_after_transaction_commit =
            ActiveJob.gem_version >= Gem::Version.new("8.0") ? true : :always

          ActiveRecord::Base.transaction do
            dispatcher.call(MyBulkEnqueueHandler, event, record)
            dispatcher.call(MyBulkEnqueueHandler, other_event, other_record)
          end

          expect(enqueued_event_ids).to eq([event.event_id, other_event.event_id])
        ensure
          MyBulkEnqueueHandler.enqueue_after_transaction_commit = original
        end
      end
    end

    class MyBulkEnqueueHandler < ActiveJob::Base
      def perform(event)
      end
    end
  end
end
