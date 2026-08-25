# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/dispatcher_lint"

module RailsEventStore
  ::RSpec.describe AfterCommitBulkDispatcher do
    around { |example| ActiveJob::Base.with(logger: nil, queue_adapter: :test) { example.run } }

    it_behaves_like "dispatcher",
                    described_class.new(
                      scheduler: ActiveJobBulkScheduler.new(serializer: RubyEventStore::Serializers::YAML),
                    )

    let(:scheduler) { ActiveJobBulkScheduler.new(serializer: RubyEventStore::Serializers::YAML) }
    let(:dispatcher) { described_class.new(scheduler: scheduler) }

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

    it "dispatches immediately when no transaction is open" do
      dispatcher.call(MyBulkDispatcherHandler, event, record)

      expect(enqueued_jobs.size).to eq(1)
    end

    it "buffers within a transaction and enqueues everything with a single perform_all_later on commit" do
      expect(ActiveJob).to receive(:perform_all_later).once.and_call_original

      ActiveRecord::Base.transaction do
        dispatcher.call(MyBulkDispatcherHandler, event, record)
        dispatcher.call(MyBulkDispatcherHandler, other_event, other_record)
        expect(enqueued_jobs).to be_empty
      end

      expect(enqueued_jobs).to match([
        hash_including(job: MyBulkDispatcherHandler, queue: "default"),
        hash_including(job: MyBulkDispatcherHandler, queue: "default")
      ])

      expect(enqueued_jobs.map { |job| job[:args].first["event_id"] }).to eq([event.event_id, other_event.event_id])
    end

    context "when the transaction is rolled back" do
      it "does not enqueue anything" do
        ActiveRecord::Base.transaction do
          dispatcher.call(MyBulkDispatcherHandler, event, record)
          raise ActiveRecord::Rollback
        end

        expect(enqueued_jobs).to be_empty
      end
    end

    context "when the scheduler does not support #bulk_call" do
      let(:scheduler) { ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML) }

      it "falls back to the scheduler's #call method after commit" do
        expect(ActiveJob).not_to receive(:perform_all_later)

        ActiveRecord::Base.transaction do
          dispatcher.call(MyBulkDispatcherHandler, event, record)
          dispatcher.call(MyBulkDispatcherHandler, other_event, other_record)
          expect(enqueued_jobs).to be_empty
        end

        expect(enqueued_jobs.size).to eq(2)
      end
    end

    it "uses ActiveRecord::Base.connection when .lease_connection is not available (ActiveRecord <7.2)" do
      allow(ActiveRecord::Base).to receive(:lease_connection).and_return(nil)
      allow(ActiveRecord::Base).to receive(:connection).and_call_original

      dispatcher.call(MyBulkDispatcherHandler, event, record)

      expect(ActiveRecord::Base).to have_received(:lease_connection)
      expect(ActiveRecord::Base).to have_received(:connection)
    end

    describe "registry cleanup" do
      def registry
        Thread.current[described_class::REGISTRY_KEY]
      end

      it "removes the buffered batch after commit" do
        ActiveRecord::Base.transaction do
          dispatcher.call(MyBulkDispatcherHandler, event, record)
          expect(registry).not_to be_empty
        end

        expect(registry).to be_empty
      end

      it "removes the buffered batch after rollback" do
        ActiveRecord::Base.transaction do
          dispatcher.call(MyBulkDispatcherHandler, event, record)
          expect(registry).not_to be_empty
          raise ActiveRecord::Rollback
        end

        expect(registry).to be_empty
      end
    end

    describe "#verify" do
      specify { expect(dispatcher.verify(MyBulkDispatcherHandler)).to be(true) }
    end

    class MyBulkDispatcherHandler < ActiveJob::Base
      def perform(event)
      end
    end
  end
end
