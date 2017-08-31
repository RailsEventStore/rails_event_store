require 'spec_helper'
require 'active_job'
require 'ruby_event_store'
require 'ruby_event_store/spec/dispatcher_lint'

module RailsEventStore
  RSpec.describe ActiveJobDispatcher do
    it_behaves_like :dispatcher, ActiveJobDispatcher.new

    it "builds sync proxy for callable class" do
      handler = ActiveJobDispatcher.new.proxy_for(CallableHandler)
      expect(handler.respond_to?(:call)).to be_truthy
      expect_any_instance_of(CallableHandler).to receive(:call)
      handler.call(DummyEvent.new)
    end

    it "builds async proxy for ActiveJob::Base ancestors" do
      AsyncHandler.queue_adapter = :test
      AsyncHandler.queue_adapter.perform_enqueued_jobs = true
      AsyncHandler.queue_adapter.perform_enqueued_at_jobs = true
      handler = ActiveJobDispatcher.new.proxy_for(AsyncHandler)

      expect(handler.respond_to?(:call)).to be_truthy
      event = DummyEvent.new
      yaml = YAML.dump(event)
      expect(AsyncHandler.received).to be_nil
      expect(AsyncHandler).to receive(:perform_later).with(yaml).and_call_original
      expect_any_instance_of(AsyncHandler).to receive(:perform).with(yaml)
      handler.call(event)
      expect(AsyncHandler.received).to eq(yaml)
    end

    it "async proxy for defined adapter enqueue job immidiatelly when no transaction is open" do
      AsyncHandler.queue_adapter = DummyAdapter.new
      AsyncHandler.queue_adapter.perform_enqueued_jobs = true
      AsyncHandler.queue_adapter.perform_enqueued_at_jobs = true
      handler = ActiveJobDispatcher.new.proxy_for(AsyncHandler)

      expect(handler.respond_to?(:call)).to be_truthy
      event = DummyEvent.new
      yaml = YAML.dump(event)
      expect(AsyncHandler.received).to be_nil
      expect(AsyncHandler).to receive(:perform_later).with(yaml).and_call_original
      expect_any_instance_of(AsyncHandler).to receive(:perform).with(yaml)
      handler.call(event)
      expect(AsyncHandler.received).to eq(yaml)
    end

    it "async proxy for defined adapter enqueue job only after transaction commit" do
      AsyncHandler.queue_adapter = DummyAdapter.new
      AsyncHandler.queue_adapter.perform_enqueued_jobs = true
      AsyncHandler.queue_adapter.perform_enqueued_at_jobs = true
      handler = ActiveJobDispatcher.new.proxy_for(AsyncHandler)

      expect(handler.respond_to?(:call)).to be_truthy
      event = DummyEvent.new
      yaml = YAML.dump(event)
      expect(AsyncHandler).to receive(:perform_later).with(yaml).and_call_original
      expect_any_instance_of(AsyncHandler).to receive(:perform).with(yaml)
      ActiveRecord::Base.transaction do
        handler.call(event)
        expect(AsyncHandler.received).to be_nil
      end
      expect(AsyncHandler.received).to eq(yaml)
    end

    private
    DummyAdapter = Class.new(ActiveJob::QueueAdapters::TestAdapter)
    DummyEvent = Class.new(RailsEventStore::Event)

    class CallableHandler
      @@received = nil
      def self.received
        @@received
      end
      def call(event)
        @@received = event
      end
    end

    class AsyncHandler < ActiveJob::Base
      @@received = nil
      def self.received
        @@received
      end
      def perform(event)
        @@received = event
      end
    end
  end
end
