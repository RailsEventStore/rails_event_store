require 'spec_helper'
require 'active_job'
require 'ruby_event_store'
require 'ruby_event_store/spec/dispatcher_lint'

module RailsEventStore
  RSpec.describe ActiveJobDispatcher do
    it_behaves_like :dispatcher, ActiveJobDispatcher.new

    around do |example|
      with_queue_adapter(ActiveJob::Base, :test) do
        original_logger = ActiveJob::Base.logger
        ActiveJob::Base.logger = Logger.new(nil) # Silence messages "[ActiveJob] Enqueued ...".
        example.run
        ActiveJob::Base.logger = original_logger
      end
    end

    before(:each) do
      CallableHandler.reset
      AsyncHandler.reset
    end

    let!(:event) { RailsEventStore::Event.new }
    let!(:yaml)  { YAML.dump(event) }

    it "builds sync proxy for callable class" do
      handler = ActiveJobDispatcher.new.proxy_for(CallableHandler)
      expect(handler.respond_to?(:call)).to be_truthy
      expect_any_instance_of(CallableHandler).to receive(:call).and_call_original
      expect_no_enqueued_job do
        handler.call(event)
      end
    end

    it "builds async proxy for ActiveJob::Base ancestors" do
      handler = ActiveJobDispatcher.new.proxy_for(AsyncHandler)

      expect(handler.respond_to?(:call)).to be_truthy
      expect_to_have_enqueued_job(AsyncHandler) do
        handler.call(event)
      end
      expect(AsyncHandler.received).to be_nil
      perform_enqueued_jobs(AsyncHandler.queue_adapter)
      expect(AsyncHandler.received).to eq(yaml)
    end

    it "async proxy for defined adapter enqueue job immediately when no transaction is open" do
      with_queue_adapter(AsyncHandler, DummyAdapter.new) do
        handler = ActiveJobDispatcher.new.proxy_for(AsyncHandler)

        expect(handler.respond_to?(:call)).to be_truthy
        expect_to_have_enqueued_job(AsyncHandler) do
          handler.call(event)
        end
        expect(AsyncHandler.received).to be_nil
        perform_enqueued_jobs(AsyncHandler.queue_adapter)
        expect(AsyncHandler.received).to eq(yaml)
      end
    end

    it "async proxy for defined adapter enqueue job only after transaction commit" do
      with_queue_adapter(AsyncHandler, DummyAdapter.new) do
        handler = ActiveJobDispatcher.new.proxy_for(AsyncHandler)

        expect(handler.respond_to?(:call)).to be_truthy
        expect_to_have_enqueued_job(AsyncHandler) do
          ActiveRecord::Base.transaction do
            handler.call(event)
          end
        end
        expect(AsyncHandler.received).to be_nil
        perform_enqueued_jobs(AsyncHandler.queue_adapter)
        expect(AsyncHandler.received).to eq(yaml)
      end
    end

    it "async proxy for defined adapter do not enqueue job after transaction rollback" do
      with_queue_adapter(AsyncHandler, DummyAdapter.new) do
        handler = ActiveJobDispatcher.new.proxy_for(AsyncHandler)

        expect_no_enqueued_job(AsyncHandler) do
          ActiveRecord::Base.transaction do
            handler.call(event)
            raise ActiveRecord::Rollback
          end
        end
        expect(AsyncHandler.received).to be_nil
      end
    end

    def with_queue_adapter(job, queue_adapter, &proc)
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
        #expect {
        #}.to have_enqueued_job(AsyncHandler)
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
    DummyAdapter = Class.new(ActiveJob::QueueAdapters::TestAdapter)

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
