require 'spec_helper'
require 'ruby_event_store/spec/dispatcher_lint'
require 'active_support/notifications'

module RubyEventStore
  RSpec.describe InstrumentedDispatcher do
    it_behaves_like :dispatcher, InstrumentedDispatcher.new(PubSub::Dispatcher.new, ActiveSupport::Notifications)

    describe "#call" do
      specify "wraps around original implementation" do
        some_dispatcher = spy
        instrumented_dispatcher = InstrumentedDispatcher.new(some_dispatcher, ActiveSupport::Notifications)
        event = Object.new
        serialized_event = Object.new
        subscriber = -> { }

        instrumented_dispatcher.call(subscriber, event, serialized_event)

        expect(some_dispatcher).to have_received(:call).with(subscriber, event, serialized_event)
      end

      specify "instruments" do
        instrumented_dispatcher = InstrumentedDispatcher.new(spy, ActiveSupport::Notifications)
        subscribe_to("dispatch.dispatcher.rails_event_store") do |notification_calls|
          event = Object.new
          serialized_event = Object.new
          subscriber = -> { }

          instrumented_dispatcher.call(subscriber, event, serialized_event)

          expect(notification_calls).to eq([
            { event: event, subscriber: subscriber }
          ])
        end
      end
    end

    describe "#verify" do
      specify "wraps around original implementation" do
        some_dispatcher = spy
        instrumented_dispatcher = InstrumentedDispatcher.new(some_dispatcher, ActiveSupport::Notifications)
        subscriber = -> { }

        instrumented_dispatcher.verify(subscriber)

        expect(some_dispatcher).to have_received(:verify).with(subscriber)
      end
    end

    def subscribe_to(name)
      received_payloads = []
      callback = ->(_name, _start, _finish, _id, payload) { received_payloads << payload }
      ActiveSupport::Notifications.subscribed(callback, name) do
        yield received_payloads
      end
    end
  end
end
