# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/dispatcher_lint"

module RailsEventStore
  ::RSpec.describe AfterCommitDispatcher do
    DummyError2 = Class.new(StandardError)

    class DummyRecord2 < ActiveRecord::Base
      self.table_name = "dummy_records"
      after_commit -> { raise DummyError2 }
    end

    it_behaves_like "dispatcher",
                    AfterCommitDispatcher.new(
                      scheduler: ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML),
                    )

    let(:event) { TimeEnrichment.with(RubyEventStore::Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8")) }
    let(:record) { RubyEventStore::Mappers::Default.new.event_to_record(event) }
    let(:serialized_record) { record.serialize(RubyEventStore::Serializers::YAML).to_h.transform_keys(&:to_s) }

    let(:dispatcher) do
      AfterCommitDispatcher.new(scheduler: ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML))
    end

    before { MyActiveJobAsyncHandler2.reset }

    it "dispatch job immediately when no transaction is open" do
      expect_to_have_enqueued_job(MyActiveJobAsyncHandler2) { dispatcher.call(MyActiveJobAsyncHandler2, event, record) }
      expect(MyActiveJobAsyncHandler2.received).to be_nil
      MyActiveJobAsyncHandler2.perform_enqueued_jobs
      expect(MyActiveJobAsyncHandler2.received).to eq(serialized_record)
    end

    it "dispatch job only after transaction commit" do
      expect_to_have_enqueued_job(MyActiveJobAsyncHandler2) do
        ActiveRecord::Base.transaction do
          expect_no_enqueued_job(MyActiveJobAsyncHandler2) { dispatcher.call(MyActiveJobAsyncHandler2, event, record) }
        end
      end
      expect(MyActiveJobAsyncHandler2.received).to be_nil
      MyActiveJobAsyncHandler2.perform_enqueued_jobs
      expect(MyActiveJobAsyncHandler2.received).to eq(serialized_record)
    end

    it "uses ActiveRecord::Base.connection when .lease_connection is not available (ActiveRecord <7.2)" do
      allow(ActiveRecord::Base).to receive(:lease_connection).and_return(nil)
      allow(ActiveRecord::Base).to receive(:connection).and_call_original

      dispatcher.call(MyActiveJobAsyncHandler2, event, record)

      expect(ActiveRecord::Base).to have_received(:lease_connection)
      expect(ActiveRecord::Base).to have_received(:connection)
    end

    context "when transaction is rolledback" do
      it "does not dispatch job" do
        expect_no_enqueued_job(MyActiveJobAsyncHandler2) do
          ActiveRecord::Base.transaction do
            dispatcher.call(MyActiveJobAsyncHandler2, event, record)
            raise ::ActiveRecord::Rollback
          end
        end
        MyActiveJobAsyncHandler2.perform_enqueued_jobs
        expect(MyActiveJobAsyncHandler2.received).to be_nil
      end
    end

    describe "#verify" do
      specify { expect(dispatcher.verify(MyActiveJobAsyncHandler2)).to be(true) }
    end

    describe "flushing a buffering scheduler" do
      let(:scheduler) { BufferingScheduler.new }
      let(:dispatcher) { AfterCommitDispatcher.new(scheduler: scheduler) }

      it "hands everything buffered within one transaction over in a single flush" do
        ActiveRecord::Base.transaction do
          dispatcher.call(MyActiveJobAsyncHandler2, event, record)
          dispatcher.call(MyActiveJobAsyncHandler2, event, record)
          expect(scheduler.flushed).to be_empty
        end

        expect(scheduler.flushed.size).to eq(1)
        expect(scheduler.flushed.first.size).to eq(2)
      end

      it "flushes immediately when no transaction is open" do
        dispatcher.call(MyActiveJobAsyncHandler2, event, record)

        expect(scheduler.flushed.size).to eq(1)
        expect(scheduler.flushed.first.size).to eq(1)
      end

      it "still flushes once when a nested transaction commits" do
        ActiveRecord::Base.transaction do
          dispatcher.call(MyActiveJobAsyncHandler2, event, record)
          ActiveRecord::Base.transaction(requires_new: true) do
            dispatcher.call(MyActiveJobAsyncHandler2, event, record)
          end
        end

        expect(scheduler.flushed.size).to eq(1)
        expect(scheduler.flushed.first.size).to eq(2)
      end

      it "does not flush when the transaction is rolled back" do
        ActiveRecord::Base.transaction do
          dispatcher.call(MyActiveJobAsyncHandler2, event, record)
          raise ::ActiveRecord::Rollback
        end

        expect(scheduler.flushed).to be_empty
      end

      it "does not flush when a nested transaction is rolled back" do
        ActiveRecord::Base.transaction do
          ActiveRecord::Base.transaction(requires_new: true) do
            dispatcher.call(MyActiveJobAsyncHandler2, event, record)
            raise ::ActiveRecord::Rollback
          end
        end

        expect(scheduler.flushed).to be_empty
      end
    end

    class BufferingScheduler
      attr_reader :flushed

      def initialize
        @buffer = []
        @flushed = []
      end

      def call(subscriber, record)
        @buffer << [subscriber, record]
      end

      def flush
        return if @buffer.empty?

        @flushed << @buffer.dup
        @buffer.clear
      end

      def verify(_)
        true
      end
    end

    describe "AsyncRecord" do
      let(:schedule_proc) { -> {} }
      let(:async_record) { AfterCommitDispatcher::AsyncRecord.new(schedule_proc) }

      specify "#rolledback! does nothing" do
        expect { async_record.rolledback! }.not_to raise_error
      end

      specify "#before_committed! does nothing" do
        expect { async_record.before_committed! }.not_to raise_error
      end

      specify "#trigger_transactional_callbacks? returns nil" do
        expect(async_record.trigger_transactional_callbacks?).to be_nil
      end
    end

    def expect_no_enqueued_job(job)
      raise unless block_given?
      yield
      expect(job.queued).to be_nil
    end

    def expect_to_have_enqueued_job(job)
      raise unless block_given?
      yield
      expect(job.queued).not_to be_nil
    end

    class MyActiveJobAsyncHandler2 < ActiveJob::Base
      @@received = nil
      @@queued = nil
      def self.reset
        @@received = nil
        @@queued = nil
      end
      def self.queued
        @@queued
      end
      def self.received
        @@received
      end
      def self.perform_enqueued_jobs
        @@received = @@queued
      end
      def self.perform_later(event)
        @@queued = event
      end
    end
  end
end
