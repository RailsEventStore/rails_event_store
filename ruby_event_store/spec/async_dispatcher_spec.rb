require 'spec_helper'
require 'ruby_event_store/spec/dispatcher_lint'

module RubyEventStore
  RSpec.describe AsyncDispatcher do
    class CustomScheduler
      def call(klass, serialized_event)
        klass.new.perform_async(serialized_event)
      end

      def async_handler?(klass)
        not_async_class = [CallableHandler, NotCallableHandler].include?(klass)
        !(not_async_class || klass.is_a?(CallableHandler))
      end
    end

    it_behaves_like :dispatcher, AsyncDispatcher.new(scheduler: CustomScheduler.new)

    before(:each) do
      CallableHandler.reset
      MyAsyncHandler.reset
    end

    let!(:event) { RubyEventStore::Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8") }
    let!(:serialized_event)  { RubyEventStore::Mappers::Default.new.event_to_serialized_record(event) }

    it "verification" do
      expect do
        AsyncDispatcher.new(scheduler: CustomScheduler.new).verify(NotCallableHandler)
      end.to raise_error(RubyEventStore::InvalidHandler)
      expect do
        AsyncDispatcher.new(scheduler: CustomScheduler.new).verify(MyAsyncHandler)
      end.not_to raise_error
      expect do
        AsyncDispatcher.new(scheduler: CustomScheduler.new).verify(Object.new)
      end.not_to raise_error
    end

    it "builds async proxy for async handlers" do
      expect_to_have_enqueued_job(MyAsyncHandler) do
        AsyncDispatcher.new(scheduler: CustomScheduler.new).call(MyAsyncHandler, event, serialized_event)
      end
      expect(MyAsyncHandler.received).to be_nil
      MyAsyncHandler.perform_enqueued_jobs
      expect(MyAsyncHandler.received).to eq(serialized_event)
    end

    it "calls subscribed instance" do
      handler = CallableHandler.new
      expect(handler).to receive(:call).with(event)
      AsyncDispatcher.new(scheduler: CustomScheduler.new).call(handler, event, serialized_event)
    end

    it "calls subscribed class" do
      handler = CallableHandler.new
      expect(CallableHandler).to receive(:new).and_return(handler)
      expect(handler).to receive(:call).with(event)
      AsyncDispatcher.new(scheduler: CustomScheduler.new).call(CallableHandler, event, serialized_event)
    end

    it "allows callable classes and instances" do
      expect do
        AsyncDispatcher.new(scheduler: CustomScheduler.new).verify(CallableHandler)
      end.not_to raise_error
      expect do
        AsyncDispatcher.new(scheduler: CustomScheduler.new).verify(CallableHandler.new)
      end.not_to raise_error
      expect do
        AsyncDispatcher.new(scheduler: CustomScheduler.new).verify(Proc.new{ "yo" })
      end.not_to raise_error
    end

    private

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
