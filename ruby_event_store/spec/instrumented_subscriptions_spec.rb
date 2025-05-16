# frozen_string_literal: true

require "spec_helper"
require "active_support/core_ext/object/try"
require "active_support/notifications"

module RubyEventStore
  ::RSpec.describe InstrumentedSubscriptions do
    describe "#add_subscription" do
      specify "wraps around original implementation" do
        some_subscriptions = spy
        instrumented_subscriptions = InstrumentedSubscriptions.new(some_subscriptions, ActiveSupport::Notifications)
        event_types = ["some_event_type"]
        subscriber = -> {}

        instrumented_subscriptions.add_subscription(subscriber, event_types)

        expect(some_subscriptions).to have_received(:add_subscription).with(subscriber, event_types)
      end

      specify "instruments" do
        instrumented_subscriptions = InstrumentedSubscriptions.new(spy, ActiveSupport::Notifications)
        subscribe_to("add.subscriptions.rails_event_store") do |notification_calls|
          event_types = ["some_event_type"]
          subscriber = -> {}

          instrumented_subscriptions.add_subscription(subscriber, event_types)

          expect(notification_calls).to eq([{ subscriber: subscriber, event_types: event_types }])
        end
      end
    end

    describe "#add_global_subscription" do
      specify "wraps around original implementation" do
        some_subscriptions = spy
        instrumented_subscriptions = InstrumentedSubscriptions.new(some_subscriptions, ActiveSupport::Notifications)
        subscriber = -> {}

        instrumented_subscriptions.add_global_subscription(subscriber)

        expect(some_subscriptions).to have_received(:add_global_subscription).with(subscriber)
      end

      specify "instruments" do
        instrumented_subscriptions = InstrumentedSubscriptions.new(spy, ActiveSupport::Notifications)
        subscribe_to("add.subscriptions.rails_event_store") do |notification_calls|
          subscriber = -> {}

          instrumented_subscriptions.add_global_subscription(subscriber)

          expect(notification_calls).to eq([{ subscriber: subscriber }])
        end
      end
    end

    describe "#add_thread_subscription" do
      specify "wraps around original implementation" do
        some_subscriptions = spy
        instrumented_subscriptions = InstrumentedSubscriptions.new(some_subscriptions, ActiveSupport::Notifications)
        event_types = ["some_event_type"]
        subscriber = -> {}

        instrumented_subscriptions.add_thread_subscription(subscriber, event_types)

        expect(some_subscriptions).to have_received(:add_thread_subscription).with(subscriber, event_types)
      end

      specify "instruments" do
        instrumented_subscriptions = InstrumentedSubscriptions.new(spy, ActiveSupport::Notifications)
        subscribe_to("add.subscriptions.rails_event_store") do |notification_calls|
          event_types = ["some_event_type"]
          subscriber = -> {}

          instrumented_subscriptions.add_thread_subscription(subscriber, event_types)

          expect(notification_calls).to eq([{ subscriber: subscriber, event_types: event_types }])
        end
      end
    end

    describe "#add_thread_global_subscription" do
      specify "wraps around original implementation" do
        some_subscriptions = spy
        instrumented_subscriptions = InstrumentedSubscriptions.new(some_subscriptions, ActiveSupport::Notifications)
        subscriber = -> {}

        instrumented_subscriptions.add_thread_global_subscription(subscriber)

        expect(some_subscriptions).to have_received(:add_thread_global_subscription).with(subscriber)
      end

      specify "instruments" do
        instrumented_subscriptions = InstrumentedSubscriptions.new(spy, ActiveSupport::Notifications)
        subscribe_to("add.subscriptions.rails_event_store") do |notification_calls|
          subscriber = -> {}

          instrumented_subscriptions.add_thread_global_subscription(subscriber)

          expect(notification_calls).to eq([{ subscriber: subscriber }])
        end
      end
    end

    specify "unsubscribe is instrumented" do
      some_subscriptions = spy
      some_unsubscribe = spy
      instrumented_subscriptions = InstrumentedSubscriptions.new(some_subscriptions, ActiveSupport::Notifications)
      expect(some_subscriptions).to receive(:add_subscription).and_return(some_unsubscribe)
      subscribe_to("remove.subscriptions.rails_event_store") do |notification_calls|
        event_types = ["some_event_type"]
        subscriber = -> {}

        unsubscribe = instrumented_subscriptions.add_subscription(subscriber, event_types)
        unsubscribe.call

        expect(some_unsubscribe).to have_received(:call)
        expect(notification_calls).to eq([{ subscriber: subscriber, event_types: event_types }])
      end
    end

    specify "method unknown by instrumentation but known by subscriptions" do
      some_subscriptions = double("Some subscriptions", custom_method: 42)
      instrumented_subscriptions = InstrumentedSubscriptions.new(some_subscriptions, ActiveSupport::Notifications)
      block = -> { "block" }
      instrumented_subscriptions.custom_method("arg", keyword: "keyarg", &block)

      expect(instrumented_subscriptions).to respond_to(:custom_method)
      expect(some_subscriptions).to have_received(:custom_method).with("arg", keyword: "keyarg") do |&received_block|
        expect(received_block).to be(block)
      end
    end

    specify "method unknown by instrumentation and unknown by subscriptions" do
      some_subscriptions = Subscriptions.new
      instrumented_subscriptions = InstrumentedSubscriptions.new(some_subscriptions, ActiveSupport::Notifications)

      expect(instrumented_subscriptions).not_to respond_to(:arbitrary_method_name)
      expect do instrumented_subscriptions.arbitrary_method_name end.to raise_error(
        NoMethodError,
        /undefined method.+arbitrary_method_name.+RubyEventStore::InstrumentedSubscriptions/,
      )
    end

    def subscribe_to(name)
      received_payloads = []
      callback = ->(_name, _start, _finish, _id, payload) { received_payloads << payload }
      ActiveSupport::Notifications.subscribed(callback, name) { yield received_payloads }
    end
  end
end
