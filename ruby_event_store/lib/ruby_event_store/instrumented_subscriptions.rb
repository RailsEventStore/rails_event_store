# frozen_string_literal: true

module RubyEventStore
  class InstrumentedSubscriptions
    def initialize(subscriptions, instrumentation)
      @subscriptions = subscriptions
      @instrumentation = instrumentation
    end

    def add_subscription(subscriber, event_types)
      instrumentation.instrument("add.subscriptions.rails_event_store", subscriber: subscriber, event_types: event_types) do
        subscriptions.add_subscription(subscriber, event_types)
      end
    end

    def add_global_subscription(subscriber)
      instrumentation.instrument("global.add.subscriptions.rails_event_store", subscriber: subscriber) do
        subscriptions.add_global_subscription(subscriber)
      end
    end

    def add_thread_subscription(subscriber, event_types)
      instrumentation.instrument("thread.add.subscriptions.rails_event_store", subscriber: subscriber, event_types: event_types) do
        subscriptions.add_thread_subscription(subscriber, event_types)
      end
    end

    def add_thread_global_subscription(subscriber)
      instrumentation.instrument("thread.global.add.subscriptions.rails_event_store", subscriber: subscriber) do
        subscriptions.add_thread_global_subscription(subscriber)
      end
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

    attr_reader :instrumentation, :subscriptions
  end
end
