# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/dispatcher_lint"
require "active_support/core_ext/object/try"
require "active_support/isolated_execution_state"
require "active_support/notifications"

module RubyEventStore
  ::RSpec.describe InstrumentedDispatcher do
    it_behaves_like 'dispatcher', InstrumentedDispatcher.new(Dispatcher.new, ActiveSupport::Notifications)

    describe "#call" do
      specify "wraps around original implementation" do
        some_dispatcher = spy
        instrumented_dispatcher = InstrumentedDispatcher.new(some_dispatcher, ActiveSupport::Notifications)
        event = Object.new
        record = Object.new
        subscriber = -> {  }

        instrumented_dispatcher.call(subscriber, event, record)

        expect(some_dispatcher).to have_received(:call).with(subscriber, event, record)
      end

      specify "instruments" do
        instrumented_dispatcher = InstrumentedDispatcher.new(spy, ActiveSupport::Notifications)
        subscribe_to("call.dispatcher.rails_event_store") do |notification_calls|
          event = Object.new
          record = Object.new
          subscriber = -> {  }

          instrumented_dispatcher.call(subscriber, event, record)

          expect(notification_calls).to eq([{ event: event, subscriber: subscriber }])
        end
      end
    end

    describe "#verify" do
      specify "wraps around original implementation" do
        some_dispatcher = spy
        instrumented_dispatcher = InstrumentedDispatcher.new(some_dispatcher, ActiveSupport::Notifications)
        subscriber = -> {  }

        instrumented_dispatcher.verify(subscriber)

        expect(some_dispatcher).to have_received(:verify).with(subscriber)
      end
    end

    specify "method unknown by instrumentation but known by dispatcher" do
      some_dispatcher = double("Some dispatcher", custom_method: 42)
      instrumented_dispatcher = InstrumentedDispatcher.new(some_dispatcher, ActiveSupport::Notifications)
      block = -> { "block" }
      instrumented_dispatcher.custom_method("arg", keyword: "keyarg", &block)

      expect(instrumented_dispatcher).to respond_to(:custom_method)
      expect(some_dispatcher).to have_received(:custom_method).with("arg", keyword: "keyarg") do |&received_block|
        expect(received_block).to be(block)
      end
    end

    specify "method unknown by instrumentation and unknown by dispatcher" do
      some_dispatcher = Dispatcher.new
      instrumented_dispatcher = InstrumentedDispatcher.new(some_dispatcher, ActiveSupport::Notifications)

      expect(instrumented_dispatcher).not_to respond_to(:arbitrary_method_name)
      expect { instrumented_dispatcher.arbitrary_method_name }.to raise_error(
        NoMethodError,
        /undefined method.+arbitrary_method_name.+RubyEventStore::InstrumentedDispatcher/
      )
    end

    def subscribe_to(name)
      received_payloads = []
      callback = ->(_name, _start, _finish, _id, payload) { received_payloads << payload }
      ActiveSupport::Notifications.subscribed(callback, name) { yield received_payloads }
    end
  end
end
