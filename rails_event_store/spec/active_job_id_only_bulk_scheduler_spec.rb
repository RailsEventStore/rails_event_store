# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/scheduler_lint"

module RailsEventStore
  ::RSpec.describe ActiveJobIdOnlyBulkScheduler do
    around { |example| ActiveJob::Base.with(logger: nil, queue_adapter: :test) { example.run } }

    it_behaves_like "scheduler", ActiveJobIdOnlyBulkScheduler.new

    let(:scheduler) { ActiveJobIdOnlyBulkScheduler.new }

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

    specify "enqueues the same payload ActiveJobIdOnlyScheduler does" do
      scheduler.call(MyIdOnlyBulkHandler, record)
      scheduler.flush

      expect(enqueued_jobs).to match(
        [
          hash_including(
            job: MyIdOnlyBulkHandler,
            queue: "default",
            args: [{ "event_id" => event.event_id, "_aj_symbol_keys" => [] }],
          ),
        ],
      )
    end

    specify "enqueues a whole transaction with a single perform_all_later" do
      dispatcher = AfterCommitDispatcher.new(scheduler: scheduler)

      expect(ActiveJob).to receive(:perform_all_later).once.and_call_original

      ActiveRecord::Base.transaction do
        dispatcher.call(MyIdOnlyBulkHandler, event, record)
        dispatcher.call(MyIdOnlyBulkHandler, other_event, other_record)
      end

      expect(enqueued_jobs.map { |job| job[:args].first["event_id"] }).to eq([event.event_id, other_event.event_id])
    end

    describe "#verify" do
      specify "accepts an ActiveJob class" do
        expect(scheduler.verify(MyIdOnlyBulkHandler)).to be(true)
      end

      specify "rejects an ActiveJob::ConfiguredJob" do
        expect(scheduler.verify(MyIdOnlyBulkHandler.set(queue: "specific"))).to be(false)
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

    class MyIdOnlyBulkHandler < ActiveJob::Base
      def perform(event)
      end
    end
  end
end
