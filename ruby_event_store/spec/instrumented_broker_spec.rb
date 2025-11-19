# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/broker_lint"
require "active_support/core_ext/object/try"
require "active_support/isolated_execution_state"
require "active_support/notifications"

module RubyEventStore
  ::RSpec.describe InstrumentedBroker do
    describe "#call" do
      specify "wraps around original implementation" do
        some_broker = spy
        instrumented_broker = InstrumentedBroker.new(some_broker, ActiveSupport::Notifications)
        event = Object.new
        record = Object.new

        expect(some_broker).to receive(:public_method).with(:call).and_return(double(arity: 3))
        instrumented_broker.call("topic", event, record)

        expect(some_broker).to have_received(:call).with("topic", event, record)
      end

      specify "wraps around legacy implementation" do
        some_broker = spy
        instrumented_broker = InstrumentedBroker.new(some_broker, ActiveSupport::Notifications)
        event = Object.new
        record = Object.new

        expect(some_broker).to receive(:public_method).with(:call).and_return(double(arity: 2))
        expect { instrumented_broker.call("topic", event, record) }.to output(<<~EOS).to_stderr
            Message broker shall support topics.
            Topic WILL BE IGNORED in the current broker.
            Modify the broker implementation to pass topic as an argument to broker.call method.
          EOS

        expect(some_broker).to have_received(:call).with(event, record)
      end

      specify "instruments" do
        some_broker = spy
        instrumented_broker = InstrumentedBroker.new(some_broker, ActiveSupport::Notifications)
        subscribe_to("call.broker.rails_event_store") do |notification_calls|
          event = Object.new
          record = Object.new

          expect(some_broker).to receive(:public_method).with(:call).and_return(double(arity: 3))
          instrumented_broker.call("topic", event, record)

          expect(notification_calls).to eq([{ topic: "topic", event: event, record: record }])
        end
      end
    end

    describe "#add_subscription" do
      specify "wraps around original implementation" do
        some_broker = spy
        instrumented_broker = InstrumentedBroker.new(some_broker, ActiveSupport::Notifications)
        subscriber = -> {}
        topics = []

        instrumented_broker.add_subscription(subscriber, topics)

        expect(some_broker).to have_received(:add_subscription).with(subscriber, topics)
      end

      specify "instruments" do
        instrumented_broker = InstrumentedBroker.new(spy, ActiveSupport::Notifications)
        subscribe_to("add_subscription.broker.rails_event_store") do |notification_calls|
          subscriber = -> {}
          topics = []

          instrumented_broker.add_subscription(subscriber, topics)

          expect(notification_calls).to eq([{ subscriber: subscriber, topics: topics }])
        end
      end
    end

    describe "#add_global_subscription" do
      specify "wraps around original implementation" do
        some_broker = spy
        instrumented_broker = InstrumentedBroker.new(some_broker, ActiveSupport::Notifications)
        subscriber = -> {}

        instrumented_broker.add_global_subscription(subscriber)

        expect(some_broker).to have_received(:add_global_subscription).with(subscriber)
      end

      specify "instruments" do
        instrumented_broker = InstrumentedBroker.new(spy, ActiveSupport::Notifications)
        subscribe_to("add_global_subscription.broker.rails_event_store") do |notification_calls|
          subscriber = -> {}

          instrumented_broker.add_global_subscription(subscriber)

          expect(notification_calls).to eq([{ subscriber: subscriber }])
        end
      end
    end

    describe "#add_thread_subscription" do
      specify "wraps around original implementation" do
        some_broker = spy
        instrumented_broker = InstrumentedBroker.new(some_broker, ActiveSupport::Notifications)
        subscriber = -> {}
        topics = []

        instrumented_broker.add_thread_subscription(subscriber, topics)

        expect(some_broker).to have_received(:add_thread_subscription).with(subscriber, topics)
      end

      specify "instruments" do
        instrumented_broker = InstrumentedBroker.new(spy, ActiveSupport::Notifications)
        subscribe_to("add_thread_subscription.broker.rails_event_store") do |notification_calls|
          subscriber = -> {}
          topics = []

          instrumented_broker.add_thread_subscription(subscriber, topics)

          expect(notification_calls).to eq([{ subscriber: subscriber, topics: topics }])
        end
      end
    end

    describe "#add_thread_global_subscription" do
      specify "wraps around original implementation" do
        some_broker = spy
        instrumented_broker = InstrumentedBroker.new(some_broker, ActiveSupport::Notifications)
        subscriber = -> {}

        instrumented_broker.add_thread_global_subscription(subscriber)

        expect(some_broker).to have_received(:add_thread_global_subscription).with(subscriber)
      end

      specify "instruments" do
        instrumented_broker = InstrumentedBroker.new(spy, ActiveSupport::Notifications)
        subscribe_to("add_thread_global_subscription.broker.rails_event_store") do |notification_calls|
          subscriber = -> {}

          instrumented_broker.add_thread_global_subscription(subscriber)

          expect(notification_calls).to eq([{ subscriber: subscriber }])
        end
      end
    end

    describe "#all_subscriptions_for" do
      specify "wraps around original implementation" do
        some_broker = spy
        instrumented_broker = InstrumentedBroker.new(some_broker, ActiveSupport::Notifications)
        topic = String.new

        instrumented_broker.all_subscriptions_for(topic)

        expect(some_broker).to have_received(:all_subscriptions_for).with(topic)
      end

      specify "instruments" do
        instrumented_broker = InstrumentedBroker.new(spy, ActiveSupport::Notifications)
        subscribe_to("all_subscriptions_for.broker.rails_event_store") do |notification_calls|
          topic = String.new

          instrumented_broker.all_subscriptions_for(topic)

          expect(notification_calls).to eq([{ topic: topic }])
        end
      end
    end

    specify "method unknown by instrumentation but known by broker" do
      some_broker = double("Some broker", custom_method: 42)
      instrumented_broker = InstrumentedBroker.new(some_broker, ActiveSupport::Notifications)
      block = -> { "block" }
      instrumented_broker.custom_method("arg", keyword: "keyarg", &block)

      expect(instrumented_broker).to respond_to(:custom_method)
      expect(some_broker).to have_received(:custom_method).with("arg", keyword: "keyarg") do |&received_block|
        expect(received_block).to be(block)
      end
    end

    specify "method unknown by instrumentation and unknown by broker" do
      some_broker = Broker.new(subscriptions: Object.new, dispatcher: Object.new)
      instrumented_broker = InstrumentedBroker.new(some_broker, ActiveSupport::Notifications)

      expect(instrumented_broker).not_to respond_to(:arbitrary_method_name)
      expect { instrumented_broker.arbitrary_method_name }.to raise_error(
        NoMethodError,
        /undefined method.+arbitrary_method_name.+RubyEventStore::InstrumentedBroker/,
      )
    end

    specify "#cleaner_inspect" do
      broker = Broker.new
      instrumented_broker = InstrumentedBroker.new(broker, ActiveSupport::Notifications)
      expect(instrumented_broker.cleaner_inspect).to eq(<<~EOS.chomp)
        #<#{instrumented_broker.class.name}:0x#{instrumented_broker.object_id.to_s(16)}>
          - broker: #{broker.cleaner_inspect(indent: 2)}
      EOS
    end

    specify "#cleaner_inspect with indent" do
      broker = Broker.new
      instrumented_broker = InstrumentedBroker.new(broker, ActiveSupport::Notifications)
      expect(instrumented_broker.cleaner_inspect(indent: 4)).to eq(<<~EOS.chomp)
        #{' ' * 4}#<#{instrumented_broker.class.name}:0x#{instrumented_broker.object_id.to_s(16)}>
        #{' ' * 4}  - broker: #{broker.cleaner_inspect(indent: 6)}
      EOS
    end

    def subscribe_to(name)
      received_payloads = []
      callback = ->(_name, _start, _finish, _id, payload) { received_payloads << payload }
      ActiveSupport::Notifications.subscribed(callback, name) { yield received_payloads }
    end
  end
end
