require "spec_helper"
require "ruby_event_store/spec/dispatcher_lint"
require "ruby_event_store/spec/scheduler_lint"
require "rails_event_store"

module RubyEventStore
  ::RSpec.describe RailsEventStore::AfterCommitAsyncDispatcher do
    around(:each) do |example|
      ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
      m =
        Migrator.new(
          File.expand_path(
            "../../../ruby_event_store-active_record/lib/ruby_event_store/active_record/generators/templates",
            __dir__
          )
        )
      SilenceStdout.silence_stdout { m.run_migration("create_event_store_events") }

      example.run
    end

    DummyError = Class.new(StandardError)

    class DummyRecord < ::ActiveRecord::Base
      self.table_name = "dummy_records"
      after_commit -> { raise DummyError }
    end

    it_behaves_like :scheduler, SidekiqScheduler.new(serializer: RubyEventStore::Serializers::YAML)

    it_behaves_like :dispatcher, RailsEventStore::AfterCommitAsyncDispatcher.new(scheduler: SidekiqScheduler.new(serializer: RubyEventStore::Serializers::YAML))

    let(:event) { TimeEnrichment.with(RailsEventStore::Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8")) }
    let(:record) { RubyEventStore::Mappers::Default.new.event_to_record(event) }
    let(:serialized_record) { record.serialize(YAML).to_h.transform_keys(&:to_s) }

    let(:dispatcher) { RailsEventStore::AfterCommitAsyncDispatcher.new(scheduler: SidekiqScheduler.new(serializer: RubyEventStore::Serializers::YAML)) }

    before(:each) { TestAsyncHandler.reset }

    it "dispatch job immediately when no transaction is open" do
      expect_to_have_enqueued_job(TestAsyncHandler) { dispatcher.call(TestAsyncHandler, event, record) }
      expect(TestAsyncHandler.received).to be_nil
      TestAsyncHandler.perform_enqueued_jobs
      expect(TestAsyncHandler.received).to eq(serialized_record)
    end

    it "dispatch job only after transaction commit" do
      expect_to_have_enqueued_job(TestAsyncHandler) do
        ::ActiveRecord::Base.transaction do
          expect_no_enqueued_job(TestAsyncHandler) { dispatcher.call(TestAsyncHandler, event, record) }
        end
      end
      expect(TestAsyncHandler.received).to be_nil
      TestAsyncHandler.perform_enqueued_jobs
      expect(TestAsyncHandler.received).to eq(serialized_record)
    end

    context "when transaction is rolledback" do
      it "does not dispatch job" do
        expect_no_enqueued_job(TestAsyncHandler) do
          ::ActiveRecord::Base.transaction do
            dispatcher.call(TestAsyncHandler, event, record)
            raise ::ActiveRecord::Rollback
          end
        end
        TestAsyncHandler.perform_enqueued_jobs
        expect(TestAsyncHandler.received).to be_nil
      end

      context "when raise_in_transactional_callbacks is enabled" do
        around { |example| with_raise_in_transactional_callbacks { example.run } }

        it "does not dispatch job" do
          expect_no_enqueued_job(TestAsyncHandler) do
            ::ActiveRecord::Base.transaction do
              dispatcher.call(TestAsyncHandler, event, record)
              raise ::ActiveRecord::Rollback
            end
          end
          TestAsyncHandler.perform_enqueued_jobs
          expect(TestAsyncHandler.received).to be_nil
        end
      end
    end

    it "dispatch job only after top-level transaction (nested is not new) commit" do
      expect_to_have_enqueued_job(TestAsyncHandler) do
        ::ActiveRecord::Base.transaction do
          expect_no_enqueued_job(TestAsyncHandler) do
            ::ActiveRecord::Base.transaction(requires_new: false) { dispatcher.call(TestAsyncHandler, event, record) }
          end
        end
      end
      expect(TestAsyncHandler.received).to be_nil
      TestAsyncHandler.perform_enqueued_jobs
      expect(TestAsyncHandler.received).to eq(serialized_record)
    end

    it "dispatch job only after top-level transaction commit" do
      expect_to_have_enqueued_job(TestAsyncHandler) do
        ::ActiveRecord::Base.transaction do
          expect_no_enqueued_job(TestAsyncHandler) do
            ::ActiveRecord::Base.transaction(requires_new: true) { dispatcher.call(TestAsyncHandler, event, record) }
          end
        end
      end
      expect(TestAsyncHandler.received).to be_nil
      TestAsyncHandler.perform_enqueued_jobs
      expect(TestAsyncHandler.received).to eq(serialized_record)
    end

    it "does not dispatch job after nested transaction rollback" do
      expect_no_enqueued_job(TestAsyncHandler) do
        ::ActiveRecord::Base.transaction do
          expect_no_enqueued_job(TestAsyncHandler) do
            ::ActiveRecord::Base.transaction(requires_new: true) do
              dispatcher.call(TestAsyncHandler, event, record)
              raise ::ActiveRecord::Rollback
            end
          end
        end
      end
      TestAsyncHandler.perform_enqueued_jobs
      expect(TestAsyncHandler.received).to be_nil
    end

    context "when an exception is raised within after commit callback" do
      before { ::ActiveRecord::Schema.define { create_table(:dummy_records) } }

      it "dispatches the job after commit" do
        expect_to_have_enqueued_job(TestAsyncHandler) do
          begin
            ::ActiveRecord::Base.transaction do
              DummyRecord.new.save!
              expect_no_enqueued_job(TestAsyncHandler) { dispatcher.call(TestAsyncHandler, event, record) }
            end
          rescue DummyError
          end
        end
        expect(DummyRecord.count).to eq(1)
        expect(TestAsyncHandler.received).to be_nil

        TestAsyncHandler.perform_enqueued_jobs
        expect(TestAsyncHandler.received).to eq(serialized_record)
      end

      context "when raise_in_transactional_callbacks is enabled" do
        around { |example| with_raise_in_transactional_callbacks { example.run } }

        it "dispatches the job after commit" do
          expect_to_have_enqueued_job(TestAsyncHandler) do
            begin
              ::ActiveRecord::Base.transaction do
                DummyRecord.new.save!
                expect_no_enqueued_job(TestAsyncHandler) { dispatcher.call(TestAsyncHandler, event, record) }
              end
            rescue DummyError
            end
          end
          expect(DummyRecord.count).to eq(1)
          expect(TestAsyncHandler.received).to be_nil

          TestAsyncHandler.perform_enqueued_jobs
          expect(TestAsyncHandler.received).to eq(serialized_record)
        end
      end
    end

    context "within a non-joinable transaction" do
      around { |example| ::ActiveRecord::Base.transaction(joinable: false) { example.run } }

      it "dispatches the job" do
        expect_to_have_enqueued_job(TestAsyncHandler) { dispatcher.call(TestAsyncHandler, event, record) }
      end

      it "dispatches the job after a nested transaction commits" do
        expect_to_have_enqueued_job(TestAsyncHandler) do
          ::ActiveRecord::Base.transaction do
            expect_no_enqueued_job(TestAsyncHandler) { dispatcher.call(TestAsyncHandler, event, record) }
          end
        end
      end
    end

    describe "#verify" do
      specify { expect(dispatcher.verify(TestAsyncHandler)).to eq(true) }
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
      skip unless ::ActiveRecord::Base.respond_to?(:raise_in_transactional_callbacks)

      old_transaction_config = ::ActiveRecord::Base.raise_in_transactional_callbacks
      ::ActiveRecord::Base.raise_in_transactional_callbacks = true

      yield

      ::ActiveRecord::Base.raise_in_transactional_callbacks = old_transaction_config
    end

    private

    class TestAsyncHandler
      include ::Sidekiq::Worker

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
      def self.perform_async(event)
        @@queued = event
      end
    end
  end
end
