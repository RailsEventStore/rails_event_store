# frozen_string_literal: true

module RubyEventStore
  class InstrumentedSubscriptions
    def initialize(subscriptions, instrumentation)
      @subscriptions = subscriptions
      @instrumentation = instrumentation
    end

    def add_subscription(subscriber, event_types)
      instrument(subscriber: subscriber, event_types: event_types) do
        subscriptions.add_subscription(subscriber, event_types)
      end
    end

    def add_global_subscription(subscriber)
      instrument(subscriber: subscriber) { subscriptions.add_global_subscription(subscriber) }
    end

    def add_thread_subscription(subscriber, event_types)
      instrument(subscriber: subscriber, event_types: event_types) do
        subscriptions.add_thread_subscription(subscriber, event_types)
      end
    end

    def add_thread_global_subscription(subscriber)
      instrument(subscriber: subscriber) { subscriptions.add_thread_global_subscription(subscriber) }
    end

    def method_missing(method_name, *arguments, &block)
      if respond_to?(method_name)
        subscriptions.public_send(method_name, *arguments, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private)
      subscriptions.respond_to?(method_name)
    end

    private

    def instrument(args)
      instrumentation.instrument("add.subscriptions.rails_event_store", args) do
        unsubscribe = yield
        -> { instrumentation.instrument("remove.subscriptions.rails_event_store", args) { unsubscribe.call } }
      end
    end

    attr_reader :instrumentation, :subscriptions
  end
end
