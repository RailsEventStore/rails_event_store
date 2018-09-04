require "spec_helper"
require 'ruby_event_store/spec/dispatcher_lint'

module RubyEventStore
  RSpec.describe ComposedDispatcher do
    skippy_dispatcher = Class.new do
      def call(subscriber, event, serialized_event)
        @called = true
      end

      def verify(subscriber)
        raise InvalidHandler
      end
      attr_reader :called
    end
    it_behaves_like :dispatcher, skippy_dispatcher.new

    real_dispatcher = Class.new do
      def call(subscriber, event, serialized_event)
        @called = true
      end

      def verify(subscriber)
      end
      attr_reader :called
    end
    it_behaves_like :dispatcher, real_dispatcher.new

    it_behaves_like :dispatcher, ComposedDispatcher.new

    describe "#verify" do
      specify "pass subscriber to dispatcher" do
        dispatcher = spy
        composed_dispatcher = ComposedDispatcher.new(dispatcher)
        subscriber = double

        composed_dispatcher.verify(subscriber)

        expect(dispatcher).to have_received(:verify).with(subscriber)
      end

      specify "ok if at least one dispatcher truthy" do
        composed_dispatcher = ComposedDispatcher.new(skippy_dispatcher.new, real_dispatcher.new)

        subscriber = double
        expect do
          composed_dispatcher.verify(subscriber)
        end.not_to raise_error
      end

      specify "raise error if all dispatchers falsey" do
        composed_dispatcher = ComposedDispatcher.new(skippy_dispatcher.new)

        subscriber = double
        expect do
          composed_dispatcher.verify(subscriber)
        end.to raise_error(InvalidHandler)
      end
    end

    describe "#call" do
      specify "pass arguments to dispatcher" do
        dispatcher = spy
        composed_dispatcher = ComposedDispatcher.new(dispatcher)
        event = instance_double(::RubyEventStore::Event)
        serialized_event = instance_double(::RubyEventStore::SerializedRecord)
        subscriber = double

        composed_dispatcher.call(subscriber, event, serialized_event)

        expect(dispatcher).to have_received(:verify).with(subscriber)
        expect(dispatcher).to have_received(:call).with(subscriber, event, serialized_event)
      end

      specify "calls only verified dispatcher" do
        skippy = skippy_dispatcher.new
        real = real_dispatcher.new
        composed_dispatcher = ComposedDispatcher.new(skippy, real)
        event = instance_double(::RubyEventStore::Event)
        serialized_event = instance_double(::RubyEventStore::SerializedRecord)
        subscriber = double

        composed_dispatcher.call(subscriber, event, serialized_event)

        expect(skippy.called).to be_falsey
        expect(real.called).to be_truthy
      end

      specify "calls only first verified dispatcher" do
        real1 = real_dispatcher.new
        real2 = real_dispatcher.new
        composed_dispatcher = ComposedDispatcher.new(real1, real2)
        event = instance_double(::RubyEventStore::Event)
        serialized_event = instance_double(::RubyEventStore::SerializedRecord)
        subscriber = double

        composed_dispatcher.call(subscriber, event, serialized_event)

        expect(real1.called).to be_truthy
        expect(real2.called).to be_falsey
      end
    end
  end
end
