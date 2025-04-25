# frozen_string_literal: true

module RubyEventStore
  class Broker
    def initialize(subscriptions: Subscriptions.new, dispatcher: Dispatcher.new)
      @subscriptions = subscriptions
      @dispatcher = dispatcher
    end

    def call(event, record, topic = nil)
      subscribers = subscriptions.all_for(topic || event.event_type)
      subscribers.each { |subscriber| dispatcher.call(subscriber, event, record) }
    end

    def add_subscription(subscriber, event_types)
      verify_subscription(subscriber)
      subscriptions.add_subscription(subscriber, event_types)
    end

    def add_global_subscription(subscriber)
      verify_subscription(subscriber)
      subscriptions.add_global_subscription(subscriber)
    end

    def add_thread_subscription(subscriber, event_types)
      verify_subscription(subscriber)
      subscriptions.add_thread_subscription(subscriber, event_types)
    end

    def add_thread_global_subscription(subscriber)
      verify_subscription(subscriber)
      subscriptions.add_thread_global_subscription(subscriber)
    end

    def all_subscriptions_for(event_type)
      subscriptions.all_for(event_type)
    end

    private

    attr_reader :dispatcher, :subscriptions

    def verify_subscription(subscriber)
      raise SubscriberNotExist, "subscriber must be first argument or block" unless subscriber
      unless dispatcher.verify(subscriber)
        raise InvalidHandler.new("Handler #{subscriber} is invalid for dispatcher #{dispatcher}")
      end
    end
  end
end
