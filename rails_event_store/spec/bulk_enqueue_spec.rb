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

      specify "keeps buffers of separate scheduler instances apart" do
        other_scheduler = ActiveJobBulkScheduler.new(serializer: RubyEventStore::Serializers::YAML)

        scheduler.call(MyBulkEnqueueHandler, record)
        other_scheduler.call(MyBulkEnqueueHandler, other_record)
        scheduler.flush

        expect(enqueued_event_ids).to eq([event.event_id])
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
    end

    describe "#flush" do
      specify "enqueues everything buffered with a single perform_all_later" do
        expect(ActiveJob).to receive(:perform_all_later).once.and_call_original

        scheduler.call(MyBulkEnqueueHandler, record)
        scheduler.call(MyBulkEnqueueHandler, other_record)
        scheduler.flush

        expect(enqueued_event_ids).to eq([event.event_id, other_event.event_id])
      end

      specify "does nothing when there is nothing buffered" do
        expect(ActiveJob).not_to receive(:perform_all_later)

        scheduler.flush

        expect(enqueued_jobs).to be_empty
      end

      specify "is idempotent" do
        scheduler.call(MyBulkEnqueueHandler, record)
        scheduler.flush
        scheduler.flush

        expect(enqueued_jobs.size).to eq(1)
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

    describe "#initialize" do
      def with_active_job_version(version)
        allow(ActiveJob).to receive(:gem_version).and_return(Gem::Version.new(version))
      end

      specify "accepts the ActiveJob version in use" do
        expect { ActiveJobBulkScheduler.new(serializer: RubyEventStore::Serializers::YAML) }.not_to raise_error
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

      specify "names the including scheduler when it refuses to build" do
        with_active_job_version("7.1.5")

        expect { ActiveJobIdOnlyBulkScheduler.new }.to raise_error(
          "RailsEventStore::ActiveJobIdOnlyBulkScheduler requires Rails 7.2 or newer",
        )
      end

      specify "forwards its arguments to the scheduler it is mixed into" do
        bulk_scheduler = ActiveJobBulkScheduler.new(serializer: JSON)

        bulk_scheduler.call(MyBulkEnqueueHandler, record)
        bulk_scheduler.flush

        expect(enqueued_jobs.dig(0, :args, 0)).to include("data" => "{}")
      end

      specify "builds a scheduler that takes no arguments" do
        expect { ActiveJobIdOnlyBulkScheduler.new }.not_to raise_error
      end
    end

    class MyBulkEnqueueHandler < ActiveJob::Base
      def perform(event)
      end
    end
  end
end
