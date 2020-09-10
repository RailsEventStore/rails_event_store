require 'spec_helper'
require 'ruby_event_store/spec/dispatcher_lint'
require 'ruby_event_store/spec/scheduler_lint'

module RubyEventStore
  RSpec.describe ImmediateAsyncDispatcher do
    class MyCustomScheduler
      def call(klass, record)
        klass.perform_async(record)
      end

      def verify(klass)
        klass.respond_to?(:perform_async)
      end
    end

    it_behaves_like :dispatcher, ImmediateAsyncDispatcher.new(scheduler: MyCustomScheduler.new)
    it_behaves_like :scheduler, MyCustomScheduler.new

    let(:event) { instance_double(::RubyEventStore::Event) }
    let(:record) { instance_double(::RubyEventStore::Record)  }
    let(:scheduler) { MyCustomScheduler.new }

    describe "#call" do
      specify do
        dispatcher = ImmediateAsyncDispatcher.new(scheduler: scheduler)

        handler = spy
        dispatcher.call(handler, event, record)

        expect(handler).to have_received(:perform_async).with(record)
      end
    end

    describe "#verify" do
      specify do
        dispatcher = ImmediateAsyncDispatcher.new(scheduler: scheduler)

        handler = double(perform_async: true)
        expect(dispatcher.verify(handler)).to eq(true)
      end

      specify do
        dispatcher = ImmediateAsyncDispatcher.new(scheduler: scheduler)

        handler = double
        expect(dispatcher.verify(handler)).to eq(false)
      end
    end
  end
end
