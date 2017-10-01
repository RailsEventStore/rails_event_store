require 'spec_helper'
require 'active_job'
require 'ruby_event_store'
require 'ruby_event_store/spec/dispatcher_lint'

module RailsEventStore
  RSpec.describe ActiveJobDispatcher do
    it_behaves_like :dispatcher, ActiveJobDispatcher.new

    around do |example|
      with_queue_adapter(ActiveJob::Base) do
        begin
          original_logger = ActiveJob::Base.logger
          ActiveJob::Base.logger = nil
          example.run
        ensure
          ActiveJob::Base.logger = original_logger
        end
      end
    end

    before(:each) do
      CallableHandler.reset
      AsyncHandler.reset
    end

    let!(:event) { RailsEventStore::Event.new }
    let!(:yaml)  { YAML.dump(event) }

    it "verification" do
      expect do
        ActiveJobDispatcher.new.verify(AsyncHandler)
      end.not_to raise_error
      expect do
        ActiveJobDispatcher.new.verify(ActiveJob::Base)
      end.to raise_error(RubyEventStore::InvalidHandler)
      expect do
        ActiveJobDispatcher.new.verify(Object.new)
      end.to raise_error(RubyEventStore::InvalidHandler)
    end

    it "builds async proxy for ActiveJob::Base ancestors" do
      expect_to_have_enqueued_job(AsyncHandler) do
        ActiveJobDispatcher.new.call(AsyncHandler, event)
      end
      expect(AsyncHandler.received).to be_nil
      perform_enqueued_jobs(AsyncHandler.queue_adapter)
      expect(AsyncHandler.received).to eq(yaml)
    end

    it "async proxy for defined adapter enqueue job immediately when no transaction is open" do
      dispatcher = ActiveJobDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new)
      expect_to_have_enqueued_job(AsyncHandler) do
        dispatcher.call(AsyncHandler, event)
      end
      expect(AsyncHandler.received).to be_nil
      perform_enqueued_jobs(AsyncHandler.queue_adapter)
      expect(AsyncHandler.received).to eq(yaml)
    end

    it "async proxy for defined adapter enqueue job only after transaction commit" do
      dispatcher = ActiveJobDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new)
      expect_to_have_enqueued_job(AsyncHandler) do
        ActiveRecord::Base.transaction do
          expect_no_enqueued_job do
            dispatcher.call(AsyncHandler, event)
          end
        end
      end
      expect(AsyncHandler.received).to be_nil
      perform_enqueued_jobs(AsyncHandler.queue_adapter)
      expect(AsyncHandler.received).to eq(yaml)
    end

    it "async proxy for defined adapter do not enqueue job after transaction rollback" do
      dispatcher = ActiveJobDispatcher.new(proxy_strategy: AsyncProxyStrategy::AfterCommit.new)
      expect_no_enqueued_job(AsyncHandler) do
        ActiveRecord::Base.transaction do
          dispatcher.call(AsyncHandler, event)
          raise ActiveRecord::Rollback
        end
      end
      perform_enqueued_jobs(AsyncHandler.queue_adapter)
      expect(AsyncHandler.received).to be_nil
    end

    def with_queue_adapter(job, queue_adapter = :test, &proc)
      raise unless block_given?
      adapter = job.queue_adapter
      job.queue_adapter = queue_adapter
      yield
      job.queue_adapter = adapter
    end

    def expect_no_enqueued_job(job = ActiveJob::Base, &proc)
      raise unless block_given?
      yield
      expect(job.queue_adapter.enqueued_jobs).to be_empty
    end

    def expect_to_have_enqueued_job(job, &proc)
      raise unless block_given?
      yield
      found = job.queue_adapter.enqueued_jobs.select{|enqueued| enqueued[:job] == job}.count
      expect(found).to eq(1)
    end

    def perform_enqueued_jobs(queue_adapter)
      queue_adapter.enqueued_jobs.each do |enqueued|
        enqueued[:job].perform_now(*enqueued[:args])
      end
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

    class AsyncHandler < ActiveJob::Base
      @@received = nil
      def self.reset
        @@received = nil
      end
      def self.received
        @@received
      end
      def perform(event)
        @@received = event
      end
    end
  end
end
