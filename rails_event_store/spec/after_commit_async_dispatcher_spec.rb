# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/dispatcher_lint"

module RailsEventStore
  ::RSpec.describe AfterCommitAsyncDispatcher do
    DummyError = Class.new(StandardError)

    class DummyRecord < ActiveRecord::Base
      self.table_name = "dummy_records"
      after_commit -> { raise DummyError }
    end

    it_behaves_like 'dispatcher', AfterCommitAsyncDispatcher.new(scheduler: ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML))

    let(:event) { TimeEnrichment.with(RubyEventStore::Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8")) }
    let(:record) { RubyEventStore::Mappers::Default.new.event_to_record(event) }
    let(:serialized_record) { record.serialize(RubyEventStore::Serializers::YAML).to_h.transform_keys(&:to_s) }

    let(:dispatcher) { AfterCommitAsyncDispatcher.new(scheduler: ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML)) }

    before { MyActiveJobAsyncHandler.reset }

    it "dispatch job immediately when no transaction is open" do
      expect_to_have_enqueued_job(MyActiveJobAsyncHandler) { dispatcher.call(MyActiveJobAsyncHandler, event, record) }
      expect(MyActiveJobAsyncHandler.received).to be_nil
      MyActiveJobAsyncHandler.perform_enqueued_jobs
      expect(MyActiveJobAsyncHandler.received).to eq(serialized_record)
    end

    it "dispatch job only after transaction commit" do
      expect_to_have_enqueued_job(MyActiveJobAsyncHandler) do
        ActiveRecord::Base.transaction do
          expect_no_enqueued_job(MyActiveJobAsyncHandler) { dispatcher.call(MyActiveJobAsyncHandler, event, record) }
        end
      end
      expect(MyActiveJobAsyncHandler.received).to be_nil
      MyActiveJobAsyncHandler.perform_enqueued_jobs
      expect(MyActiveJobAsyncHandler.received).to eq(serialized_record)
    end

    context "when transaction is rolledback" do
      it "does not dispatch job" do
        expect_no_enqueued_job(MyActiveJobAsyncHandler) do
          ActiveRecord::Base.transaction do
            dispatcher.call(MyActiveJobAsyncHandler, event, record)
            raise ::ActiveRecord::Rollback
          end
        end
        MyActiveJobAsyncHandler.perform_enqueued_jobs
        expect(MyActiveJobAsyncHandler.received).to be_nil
      end

      context "when raise_in_transactional_callbacks is enabled" do
        around { |example| with_raise_in_transactional_callbacks { example.run } }

        it "does not dispatch job" do
          expect_no_enqueued_job(MyActiveJobAsyncHandler) do
            ActiveRecord::Base.transaction do
              dispatcher.call(MyActiveJobAsyncHandler, event, record)
              raise ::ActiveRecord::Rollback
            end
          end
          MyActiveJobAsyncHandler.perform_enqueued_jobs
          expect(MyActiveJobAsyncHandler.received).to be_nil
        end
      end
    end

    it "dispatch job only after top-level transaction (nested is not new) commit" do
      expect_to_have_enqueued_job(MyActiveJobAsyncHandler) do
        ActiveRecord::Base.transaction do
          expect_no_enqueued_job(MyActiveJobAsyncHandler) do
            ActiveRecord::Base.transaction(requires_new: false) { dispatcher.call(MyActiveJobAsyncHandler, event, record) }
          end
        end
      end
      expect(MyActiveJobAsyncHandler.received).to be_nil
      MyActiveJobAsyncHandler.perform_enqueued_jobs
      expect(MyActiveJobAsyncHandler.received).to eq(serialized_record)
    end

    it "dispatch job only after top-level transaction commit" do
      expect_to_have_enqueued_job(MyActiveJobAsyncHandler) do
        ActiveRecord::Base.transaction do
          expect_no_enqueued_job(MyActiveJobAsyncHandler) do
            ActiveRecord::Base.transaction(requires_new: true) { dispatcher.call(MyActiveJobAsyncHandler, event, record) }
          end
        end
      end
      expect(MyActiveJobAsyncHandler.received).to be_nil
      MyActiveJobAsyncHandler.perform_enqueued_jobs
      expect(MyActiveJobAsyncHandler.received).to eq(serialized_record)
    end

    it "does not dispatch job after nested transaction rollback" do
      expect_no_enqueued_job(MyActiveJobAsyncHandler) do
        ActiveRecord::Base.transaction do
          expect_no_enqueued_job(MyActiveJobAsyncHandler) do
            ActiveRecord::Base.transaction(requires_new: true) do
              dispatcher.call(MyActiveJobAsyncHandler, event, record)
              raise ::ActiveRecord::Rollback
            end
          end
        end
      end
      MyActiveJobAsyncHandler.perform_enqueued_jobs
      expect(MyActiveJobAsyncHandler.received).to be_nil
    end

    context "when an exception is raised within after commit callback" do
      before { ActiveRecord::Schema.define { create_table(:dummy_records) } }

      it "dispatches the job after commit" do
        expect_to_have_enqueued_job(MyActiveJobAsyncHandler) do
          begin
            ActiveRecord::Base.transaction do
              DummyRecord.new.save!
              expect_no_enqueued_job(MyActiveJobAsyncHandler) { dispatcher.call(MyActiveJobAsyncHandler, event, record) }
            end
          rescue DummyError
          end
        end
        expect(DummyRecord.count).to eq(1)
        expect(MyActiveJobAsyncHandler.received).to be_nil

        MyActiveJobAsyncHandler.perform_enqueued_jobs
        expect(MyActiveJobAsyncHandler.received).to eq(serialized_record)
      end

      context "when raise_in_transactional_callbacks is enabled" do
        around { |example| with_raise_in_transactional_callbacks { example.run } }

        it "dispatches the job after commit" do
          expect_to_have_enqueued_job(MyActiveJobAsyncHandler) do
            begin
              ActiveRecord::Base.transaction do
                DummyRecord.new.save!
                expect_no_enqueued_job(MyActiveJobAsyncHandler) { dispatcher.call(MyActiveJobAsyncHandler, event, record) }
              end
            rescue DummyError
            end
          end
          expect(DummyRecord.count).to eq(1)
          expect(MyActiveJobAsyncHandler.received).to be_nil

          MyActiveJobAsyncHandler.perform_enqueued_jobs
          expect(MyActiveJobAsyncHandler.received).to eq(serialized_record)
        end
      end
    end

    context "within a non-joinable transaction" do
      around { |example| ActiveRecord::Base.transaction(joinable: false) { example.run } }

      it "dispatches the job" do
        expect_to_have_enqueued_job(MyActiveJobAsyncHandler) { dispatcher.call(MyActiveJobAsyncHandler, event, record) }
      end

      it "dispatches the job after a nested transaction commits" do
        expect_to_have_enqueued_job(MyActiveJobAsyncHandler) do
          ActiveRecord::Base.transaction do
            expect_no_enqueued_job(MyActiveJobAsyncHandler) { dispatcher.call(MyActiveJobAsyncHandler, event, record) }
          end
        end
      end
    end

    describe "#verify" do
      specify { expect(dispatcher.verify(MyActiveJobAsyncHandler)).to be(true) }
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

    def with_raise_in_transactional_callbacks
      skip unless ActiveRecord::Base.respond_to?(:raise_in_transactional_callbacks)

      old_transaction_config = ActiveRecord::Base.raise_in_transactional_callbacks
      ActiveRecord::Base.raise_in_transactional_callbacks = true

      yield

      ActiveRecord::Base.raise_in_transactional_callbacks = old_transaction_config
    end

    class MyActiveJobAsyncHandler < ActiveJob::Base
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
