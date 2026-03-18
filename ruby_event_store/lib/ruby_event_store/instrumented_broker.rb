# frozen_string_literal: true

module RubyEventStore
  class InstrumentedBroker
    DEPRECATION_MESSAGE = <<~EOW
      Instrumentation event names *.rails_event_store are deprecated and will be removed in the next major release.
      Use *.ruby_event_store instead.
    EOW
    private_constant :DEPRECATION_MESSAGE

    def initialize(broker, instrumentation)
      @broker = broker
      @instrumentation = instrumentation
    end

    def call(topic, event, record)
      instrumentation.instrument("call.broker.ruby_event_store", topic: topic, event: event, record: record) do
        deprecated_instrument("call.broker.rails_event_store", topic: topic, event: event, record: record) do
          if broker.public_method(:call).arity == 3
            broker.call(topic, event, record)
          else
            warn <<~EOW
              Message broker shall support topics.
              Topic WILL BE IGNORED in the current broker.
              Modify the broker implementation to pass topic as an argument to broker.call method.
            EOW
            broker.call(event, record)
          end
        end
      end
    end

    def add_subscription(subscriber, topics)
      instrumentation.instrument("add_subscription.broker.ruby_event_store", subscriber: subscriber, topics: topics) do
        deprecated_instrument("add_subscription.broker.rails_event_store", subscriber: subscriber, topics: topics) do
          broker.add_subscription(subscriber, topics)
        end
      end
    end

    def add_global_subscription(subscriber)
      instrumentation.instrument("add_global_subscription.broker.ruby_event_store", subscriber: subscriber) do
        deprecated_instrument("add_global_subscription.broker.rails_event_store", subscriber: subscriber) do
          broker.add_global_subscription(subscriber)
        end
      end
    end

    def add_thread_subscription(subscriber, topics)
      instrumentation.instrument(
        "add_thread_subscription.broker.ruby_event_store",
        subscriber: subscriber,
        topics: topics,
      ) do
        deprecated_instrument("add_thread_subscription.broker.rails_event_store", subscriber: subscriber, topics: topics) do
          broker.add_thread_subscription(subscriber, topics)
        end
      end
    end

    def add_thread_global_subscription(subscriber)
      instrumentation.instrument("add_thread_global_subscription.broker.ruby_event_store", subscriber: subscriber) do
        deprecated_instrument("add_thread_global_subscription.broker.rails_event_store", subscriber: subscriber) do
          broker.add_thread_global_subscription(subscriber)
        end
      end
    end

    def all_subscriptions_for(topic)
      instrumentation.instrument("all_subscriptions_for.broker.ruby_event_store", topic: topic) do
        deprecated_instrument("all_subscriptions_for.broker.rails_event_store", topic: topic) do
          broker.all_subscriptions_for(topic)
        end
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

    def deprecated_instrument(name, payload, &block)
      canonical_name = name.sub("rails_event_store", "ruby_event_store")
      old_listeners = instrumentation.notifier.all_listeners_for(name)
      new_listeners = instrumentation.notifier.all_listeners_for(canonical_name)
      if (old_listeners - new_listeners).any?
        warn DEPRECATION_MESSAGE
        instrumentation.instrument(name, payload, &block)
      else
        yield
      end
    end
  end
end
