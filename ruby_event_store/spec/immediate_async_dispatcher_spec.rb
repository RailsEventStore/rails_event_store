require 'spec_helper'
require 'ruby_event_store/spec/dispatcher_lint'

module RubyEventStore
  RSpec.describe ImmediateAsyncDispatcher do
    class MyCustomScheduler
      def call(klass, serialized_event)
        klass.perform_async(serialized_event)
      end

      def verify(klass)
        klass.respond_to?(:perform_async)
      end
    end

    it_behaves_like :dispatcher, ImmediateAsyncDispatcher.new(scheduler: MyCustomScheduler.new)

    let(:event) { instance_double(::RubyEventStore::Event) }
    let(:serialized_event) { instance_double(::RubyEventStore::SerializedRecord)  }
    let(:scheduler) { MyCustomScheduler.new }

    describe "#call" do
      specify do
        dispatcher = ImmediateAsyncDispatcher.new(scheduler: scheduler)

        handler = spy
        dispatcher.call(handler, event, serialized_event)

        expect(handler).to have_received(:perform_async).with(serialized_event)
      end
    end

    describe "#verify" do
      specify do
        dispatcher = ImmediateAsyncDispatcher.new(scheduler: scheduler)

        handler = double(perform_async: true)
        expect(dispatcher.verify(handler)).to eq(true)
      end
    end
  end
end
