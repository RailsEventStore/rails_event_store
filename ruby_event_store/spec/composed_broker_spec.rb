# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/broker_lint"

module RubyEventStore
  ::RSpec.describe ComposedBroker do
    sample_broker =
      Class.new do
        def initialize(expected, subscriptions: {})
          @expected = expected
          @subscriptions = subscriptions
        end

        def call(event, record, topic)
          @called = [event, record, topic]
        end

        def verify(topic) = @expected == topic
        def all_subscriptions_for(topic) = @subscriptions[topic] || []
        def add_subscription(subscriber, topics) = nil
        def add_global_subscription(subscriber) = nil
        def add_thread_subscription(subscriber, topics) = nil
        def add_thread_global_subscription(subscriber) = nil

        attr_reader :called
      end

    describe "#verify" do
      specify "pass topic to all until first verified brokers for verification" do
        skippy = sample_broker.new("skip")
        broker = sample_broker.new("test")
        another_skippy = sample_broker.new("skip this too")
        another_broker = sample_broker.new("test")
        composed_broker = ComposedBroker.new(skippy, broker, another_skippy, another_broker)

        expect(skippy).to receive(:verify).with("test").and_call_original
        expect(broker).to receive(:verify).with("test").and_call_original
        expect(another_skippy).not_to receive(:verify).with("test")
        expect(another_broker).not_to receive(:verify).with("test")
        composed_broker.verify("test")
      end

      specify "ok if at least one broker truthy" do
        composed_broker = ComposedBroker.new(sample_broker.new("skip"), sample_broker.new("test"))
        expect(composed_broker.verify("test")).to be(true)
      end

      specify "false if all brokers falsey" do
        composed_broker = ComposedBroker.new(sample_broker.new("skip"), sample_broker.new("skip this too"))
        expect(composed_broker.verify("test")).to be(false)
      end
    end

    describe "#call" do
      specify "pass arguments to first verified broker" do
        skippy = sample_broker.new("skip")
        broker = sample_broker.new("test")
        another_broker = sample_broker.new("test")
        composed_broker = ComposedBroker.new(skippy, broker, another_broker)
        event = instance_double(Event)
        record = instance_double(Record)

        composed_broker.call(event, record, "test")
        expect(skippy.called).to be_falsey
        expect(broker.called).to eq([event, record, "test"])
        expect(another_broker.called).to be_falsey
      end

      specify "warn when no broker to handle topic" do
        composed_broker = ComposedBroker.new(sample_broker.new("skip"), sample_broker.new("skip this too"))
        event = TestEvent.new
        record = instance_double(Record)

        expect { composed_broker.call(event, record, "some-topic") }.to output(<<~EOS).to_stderr
          No broker found for topic 'some-topic'. Event #{event.event_id} will not be processed.
        EOS
      end
    end

    describe "#all_subscriptions_for" do
      specify "returns all subscriptions from all brokers for given topic" do
        broker1 = sample_broker.new("test", subscriptions: { "test" => %w[sub1 sub2], "another" => ["sub3"] })
        broker2 = sample_broker.new("test", subscriptions: { "test" => ["sub4"] })
        composed_broker = ComposedBroker.new(broker1, broker2)

        expect(composed_broker.all_subscriptions_for("test")).to eq(%w[sub1 sub2 sub4])
      end
    end

    describe "define subscriptions" do
      specify "add_subscription to first verified broker" do
        composed_broker =
          ComposedBroker.new(
            broker_1 = sample_broker.new("test"),
            broker_2 = sample_broker.new("skip"),
            broker_3 = sample_broker.new("doh"),
          )
        handler = double("subscriber")
        expect(broker_1).to receive(:add_subscription).with(handler, "test")
        expect(broker_2).not_to receive(:add_subscription).with(handler, "test")
        expect(broker_3).not_to receive(:add_subscription).with(handler, "test")

        expect(broker_1).not_to receive(:add_subscription).with(handler, "doh")
        expect(broker_2).not_to receive(:add_subscription).with(handler, "doh")
        expect(broker_3).to receive(:add_subscription).with(handler, "doh")

        composed_broker.add_subscription(handler, %w[test doh])
      end

      specify "add_thread_subscription to first verified broker" do
        composed_broker =
          ComposedBroker.new(
            broker_1 = sample_broker.new("test"),
            broker_2 = sample_broker.new("skip"),
            broker_3 = sample_broker.new("doh"),
          )
        handler = double("subscriber")
        expect(broker_1).to receive(:add_thread_subscription).with(handler, "test")
        expect(broker_2).not_to receive(:add_thread_subscription).with(handler, "test")
        expect(broker_3).not_to receive(:add_thread_subscription).with(handler, "test")

        expect(broker_1).not_to receive(:add_thread_subscription).with(handler, "doh")
        expect(broker_2).not_to receive(:add_thread_subscription).with(handler, "doh")
        expect(broker_3).to receive(:add_thread_subscription).with(handler, "doh")

        composed_broker.add_thread_subscription(handler, %w[test doh])
      end

      specify "add_global_subscription to first verified broker" do
        composed_broker = ComposedBroker.new(broker_1 = sample_broker.new("skip"), broker_2 = sample_broker.new(nil))
        handler = double("subscriber")
        expect(broker_1).not_to receive(:add_global_subscription).with(handler)
        expect(broker_2).to receive(:add_global_subscription).with(handler)

        composed_broker.add_global_subscription(handler)
      end

      specify "add_thread_global_subscription to first verified broker" do
        composed_broker = ComposedBroker.new(broker_1 = sample_broker.new("skip"), broker_2 = sample_broker.new(nil))
        handler = double("subscriber")
        expect(broker_1).not_to receive(:add_thread_global_subscription).with(handler)
        expect(broker_2).to receive(:add_thread_global_subscription).with(handler)

        composed_broker.add_thread_global_subscription(handler)
      end

      specify "raise SubscriptionsNotSupported when no broker for topic" do
        composed_broker = ComposedBroker.new(sample_broker.new("skip"), sample_broker.new("skip this too"))
        handler = double("subscriber")
        expect { composed_broker.add_subscription(handler, ["some-topic"]) }.to raise_error(
          SubscriptionsNotSupported,
          "No broker found for topic 'some-topic'.",
        )
        expect { composed_broker.add_thread_subscription(handler, ["some-topic"]) }.to raise_error(
          SubscriptionsNotSupported,
          "No broker found for topic 'some-topic'.",
        )
        expect { composed_broker.add_global_subscription(handler) }.to raise_error(
          SubscriptionsNotSupported,
          "No broker found for global subscription.",
        )
        expect { composed_broker.add_thread_global_subscription(handler) }.to raise_error(
          SubscriptionsNotSupported,
          "No broker found for global subscription.",
        )
      end
    end
  end
end
