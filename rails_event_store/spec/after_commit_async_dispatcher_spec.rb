require 'spec_helper'
require 'ruby_event_store/spec/dispatcher_lint'
require 'ruby_event_store/spec/scheduler_lint'

module RailsEventStore
  RSpec.describe AfterCommitAsyncDispatcher do
    class CustomScheduler
      def call(klass, serialized_event)
        klass.perform_async(serialized_event)
      end

      def verify(klass)
        klass.respond_to?(:perform_async)
      end
    end

    let(:event) { RailsEventStore::Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8") }
    let(:serialized_event) { RubyEventStore::Mappers::Default.new.event_to_serialized_record(event) }
    it_behaves_like :scheduler, CustomScheduler.new

    it_behaves_like :dispatcher, AfterCommitAsyncDispatcher.new(scheduler: CustomScheduler.new)

    before(:each) do
      MyAsyncHandler.reset
    end

    it "dispatch job immediately when no transaction is open" do
      dispatcher = AfterCommitAsyncDispatcher.new(scheduler: CustomScheduler.new)
      expect_to_have_enqueued_job(MyAsyncHandler) do
        dispatcher.call(MyAsyncHandler, event, serialized_event)
      end
      expect(MyAsyncHandler.received).to be_nil
      MyAsyncHandler.perform_enqueued_jobs
      expect(MyAsyncHandler.received).to eq(serialized_event)
    end

    it "dispatch job only after transaction commit" do
      dispatcher = AfterCommitAsyncDispatcher.new(scheduler: CustomScheduler.new)
      expect_to_have_enqueued_job(MyAsyncHandler) do
        ActiveRecord::Base.transaction do
          expect_no_enqueued_job(MyAsyncHandler) do
            dispatcher.call(MyAsyncHandler, event, serialized_event)
          end
        end
      end
      expect(MyAsyncHandler.received).to be_nil
      MyAsyncHandler.perform_enqueued_jobs
      expect(MyAsyncHandler.received).to eq(serialized_event)
    end

    it "does not dispatch job after transaction rollback" do
      dispatcher = AfterCommitAsyncDispatcher.new(scheduler: CustomScheduler.new)
      expect_no_enqueued_job(MyAsyncHandler) do
        ActiveRecord::Base.transaction do
          dispatcher.call(MyAsyncHandler, event, serialized_event)
          raise ActiveRecord::Rollback
        end
      end
      MyAsyncHandler.perform_enqueued_jobs
      expect(MyAsyncHandler.received).to be_nil
    end

    it "does not dispatch job after transaction rollback (with raises)" do
      was = ActiveRecord::Base.raise_in_transactional_callbacks
      begin
        ActiveRecord::Base.raise_in_transactional_callbacks = true

        dispatcher = AfterCommitAsyncDispatcher.new(scheduler: CustomScheduler.new)
        expect_no_enqueued_job(MyAsyncHandler) do
          ActiveRecord::Base.transaction do
            dispatcher.call(MyAsyncHandler, event, serialized_event)
            raise ActiveRecord::Rollback
          end
        end
        MyAsyncHandler.perform_enqueued_jobs
        expect(MyAsyncHandler.received).to be_nil
      ensure
        ActiveRecord::Base.raise_in_transactional_callbacks = was
      end
    end if ActiveRecord::Base.respond_to?(:raise_in_transactional_callbacks)

    it "dispatch job only after top-level transaction (nested is not new) commit" do
      dispatcher = AfterCommitAsyncDispatcher.new(scheduler: CustomScheduler.new)
      expect_to_have_enqueued_job(MyAsyncHandler) do
        ActiveRecord::Base.transaction do
          expect_no_enqueued_job(MyAsyncHandler) do
            ActiveRecord::Base.transaction(requires_new: false) do
              dispatcher.call(MyAsyncHandler, event, serialized_event)
            end
          end
        end
      end
      expect(MyAsyncHandler.received).to be_nil
      MyAsyncHandler.perform_enqueued_jobs
      expect(MyAsyncHandler.received).to eq(serialized_event)
    end

    it "dispatch job only after top-level transaction commit" do
      dispatcher = AfterCommitAsyncDispatcher.new(scheduler: CustomScheduler.new)
      expect_to_have_enqueued_job(MyAsyncHandler) do
        ActiveRecord::Base.transaction do
          expect_no_enqueued_job(MyAsyncHandler) do
            ActiveRecord::Base.transaction(requires_new: true) do
              dispatcher.call(MyAsyncHandler, event, serialized_event)
            end
          end
        end
      end
      expect(MyAsyncHandler.received).to be_nil
      MyAsyncHandler.perform_enqueued_jobs
      expect(MyAsyncHandler.received).to eq(serialized_event)
    end

    it "does not dispatch job after nested transaction rollback" do
      dispatcher = AfterCommitAsyncDispatcher.new(scheduler: CustomScheduler.new)
      expect_no_enqueued_job(MyAsyncHandler) do
        ActiveRecord::Base.transaction do
          expect_no_enqueued_job(MyAsyncHandler) do
            ActiveRecord::Base.transaction(requires_new: true) do
              dispatcher.call(MyAsyncHandler, event, serialized_event)
              raise ActiveRecord::Rollback
            end
          end
        end
      end
      MyAsyncHandler.perform_enqueued_jobs
      expect(MyAsyncHandler.received).to be_nil
    end

    describe "#verify" do
      specify do
        dispatcher = AfterCommitAsyncDispatcher.new(scheduler: CustomScheduler.new)

        expect(dispatcher.verify(MyAsyncHandler)).to eq(true)
      end
    end

    def expect_no_enqueued_job(job, &proc)
      raise unless block_given?
      yield
      expect(job.queued).to be_nil
    end

    def expect_to_have_enqueued_job(job, &proc)
      raise unless block_given?
      yield
      expect(job.queued).not_to be_nil
    end

    class MyAsyncHandler
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
        @@queued  = event
      end
    end
  end
end
