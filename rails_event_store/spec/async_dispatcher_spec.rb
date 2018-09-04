require 'spec_helper'
require 'ruby_event_store'

module RailsEventStore
  RSpec.describe AsyncDispatcher do
    class CustomScheduler
      def call(klass, serialized_event)
        klass.new.perform_async(serialized_event)
      end

      def async_handler?(klass)
        not_async_class = [CallableHandler, NotCallableHandler].include?(klass)
        !not_async_class
      end
    end

    before(:each) do
      CallableHandler.reset
      MyAsyncHandler.reset
    end

    let!(:event) { RailsEventStore::Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8") }
    let!(:serialized_event)  { RubyEventStore::Mappers::Default.new.event_to_serialized_record(event) }

    it "async proxy for defined adapter enqueue job immediately when no transaction is open" do
      dispatcher = AsyncDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new, scheduler: CustomScheduler.new)
      expect_to_have_enqueued_job(MyAsyncHandler) do
        dispatcher.call(MyAsyncHandler, event, serialized_event)
      end
      expect(MyAsyncHandler.received).to be_nil
      MyAsyncHandler.perform_enqueued_jobs
      expect(MyAsyncHandler.received).to eq(serialized_event)
    end

    it "async proxy for defined adapter enqueue job only after transaction commit" do
      dispatcher = AsyncDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new, scheduler: CustomScheduler.new)
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

    it "async proxy for defined adapter do not enqueue job after transaction rollback" do
      dispatcher = AsyncDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new, scheduler: CustomScheduler.new)
      expect_no_enqueued_job(MyAsyncHandler) do
        ActiveRecord::Base.transaction do
          dispatcher.call(MyAsyncHandler, event, serialized_event)
          raise ActiveRecord::Rollback
        end
      end
      MyAsyncHandler.perform_enqueued_jobs
      expect(MyAsyncHandler.received).to be_nil
    end

    it "async proxy for defined adapter does not enqueue job after transaction rollback (with raises)" do
      was = ActiveRecord::Base.raise_in_transactional_callbacks
      begin
        ActiveRecord::Base.raise_in_transactional_callbacks = true

        dispatcher = AsyncDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new, scheduler: CustomScheduler.new)
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

    it "async proxy for defined adapter enqueue job only after top-level transaction (nested is not new) commit" do
      dispatcher = AsyncDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new, scheduler: CustomScheduler.new)
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

    it "async proxy for defined adapter enqueue job only after top-level transaction commit" do
      dispatcher = AsyncDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new, scheduler: CustomScheduler.new)
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

    it "async proxy for defined adapter do not enqueue job after nested transaction rollback" do
      dispatcher = AsyncDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new, scheduler: CustomScheduler.new)
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

    private
    class CallableHandler
      @@received = nil
      def self.reset
        @@received = nil
      end
      def self.received
        @@received
      end
      def call(event)
        @@received = event
      end
    end
    class NotCallableHandler
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
      def perform_async(event)
        @@queued  = event
      end
    end
  end
end
