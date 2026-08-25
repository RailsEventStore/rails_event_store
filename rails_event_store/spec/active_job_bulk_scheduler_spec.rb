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
      TimeEnrichment.with(RubyEventStore::Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"), timestamp: Time.utc(2026, 8, 25))
    end
    let(:other_event) do
      TimeEnrichment.with(RubyEventStore::Event.new(event_id: "d39cb65f-bc3c-4fbb-9c48-1a6e16c0e2eb"), timestamp: Time.utc(2026, 8, 25))
    end
    let(:record) { RubyEventStore::Mappers::Default.new.event_to_record(event) }
    let(:other_record) { RubyEventStore::Mappers::Default.new.event_to_record(other_event) }

    def enqueued_jobs
      ActiveJob::Base.queue_adapter.enqueued_jobs
    end

    describe "#bulk_call" do
      specify "enqueues every job with a single perform_all_later" do
        expect(ActiveJob).to receive(:perform_all_later).once.and_call_original

        scheduler.bulk_call([[MyBulkAsyncHandler, record], [MyBulkAsyncHandler, other_record]])

        expect(enqueued_jobs.size).to eq(2)
        expect(enqueued_jobs.map { |job| job[:args].first["event_id"] }).to eq([event.event_id, other_event.event_id])
      end

      specify "serializes the record the same way #call does" do
        scheduler.bulk_call([[MyBulkAsyncHandler, record]])

        expect(enqueued_jobs.size).to eq(1)
        expect(enqueued_jobs[0]).to include(
          job: MyBulkAsyncHandler,
          args: [
            {
              "event_id" => "83c3187f-84f6-4da7-8206-73af5aca7cc8",
              "event_type" => "RubyEventStore::Event",
              "data" => "--- {}\n",
              "metadata" => "--- {}\n",
              "timestamp" => "2026-08-25T00:00:00.000000Z",
              "valid_at" => "2026-08-25T00:00:00.000000Z",
              "_aj_symbol_keys" => [],
            },
          ],
          queue: "default",
        )
      end

      specify "enqueues ActiveJob::ConfiguredJob individually, alongside the bulk enqueue" do
        scheduler.bulk_call(
          [[MyBulkAsyncHandler.set(queue: "specific"), record], [MyBulkAsyncHandler, other_record]],
        )

        expect(enqueued_jobs.size).to eq(2)
        expect(enqueued_jobs.map { |job| job[:queue] }).to match_array(%w[specific default])
      end

      specify "does nothing when there is nothing to enqueue" do
        expect(ActiveJob).not_to receive(:perform_all_later)

        scheduler.bulk_call([])

        expect(enqueued_jobs).to be_empty
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

    class MyBulkAsyncHandler < ActiveJob::Base
      def perform(event)
      end
    end
  end
end
