# frozen_string_literal: true

module RubyEventStore
  class InstrumentedBroker
    def initialize(broker, instrumentation)
      @broker = broker
      @instrumentation = instrumentation
    end

    def call(topic, event, record)
      instrumentation.instrument("call.broker.rails_event_store", topic: topic, event: event, record: record) do
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

    def add_subscription(subscriber, topics)
      instrumentation.instrument("add_subscription.broker.rails_event_store", subscriber: subscriber, topics: topics) do
        broker.add_subscription(subscriber, topics)
      end
    end

    def add_global_subscription(subscriber)
      instrumentation.instrument("add_global_subscription.broker.rails_event_store", subscriber: subscriber) do
        broker.add_global_subscription(subscriber)
      end
    end

    def add_thread_subscription(subscriber, topics)
      instrumentation.instrument(
        "add_thread_subscription.broker.rails_event_store",
        subscriber: subscriber,
        topics: topics,
      ) { broker.add_thread_subscription(subscriber, topics) }
    end

    def add_thread_global_subscription(subscriber)
      instrumentation.instrument("add_thread_global_subscription.broker.rails_event_store", subscriber: subscriber) do
        broker.add_thread_global_subscription(subscriber)
      end
    end

    def all_subscriptions_for(topic)
      instrumentation.instrument("all_subscriptions_for.broker.rails_event_store", topic: topic) do
        broker.all_subscriptions_for(topic)
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

    def cleaner_inspect(indent: 0)
      <<~EOS.chomp
        #{' ' * indent}#<#{self.class}:0x#{__id__.to_s(16)}>
        #{' ' * indent}  - broker: #{broker.respond_to?(:cleaner_inspect) ? broker.cleaner_inspect(indent: indent + 2) : broker.inspect}
      EOS
    end

    private

    attr_reader :instrumentation, :broker
  end
end
