# frozen_string_literal: true

module RubyEventStore
  class InstrumentedBroker
    def initialize(broker, instrumentation)
      @broker = broker
      @instrumentation = instrumentation
    end

    def call(event, record, topic)
      instrumentation.instrument("call.broker.rails_event_store", event: event, record: record, topic: topic) do
        broker.call(event, record, topic)
      end
    end

    def add_subscription(subscriber, event_types)
      instrumentation.instrument(
        "add_subscription.broker.rails_event_store",
        subscriber: subscriber,
        event_types: event_types,
      ) { broker.add_subscription(subscriber, event_types) }
    end

    def add_global_subscription(subscriber)
      instrumentation.instrument("add_global_subscription.broker.rails_event_store", subscriber: subscriber) do
        broker.add_global_subscription(subscriber)
      end
    end

    def add_thread_subscription(subscriber, event_types)
      instrumentation.instrument(
        "add_thread_subscription.broker.rails_event_store",
        subscriber: subscriber,
        event_types: event_types,
      ) { broker.add_thread_subscription(subscriber, event_types) }
    end

    def add_thread_global_subscription(subscriber)
      instrumentation.instrument("add_thread_global_subscription.broker.rails_event_store", subscriber: subscriber) do
        broker.add_thread_global_subscription(subscriber)
      end
    end

    def all_subscriptions_for(event_type)
      instrumentation.instrument("all_subscriptions_for.broker.rails_event_store", event_type: event_type) do
        broker.all_subscriptions_for(event_type)
      end
    end

    def method_missing(method_name, *arguments, **keyword_arguments, &block)
      if respond_to?(method_name)
        broker.public_send(method_name, *arguments, **keyword_arguments, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private)
      broker.respond_to?(method_name)
    end

    private

    attr_reader :instrumentation, :broker
  end
end
