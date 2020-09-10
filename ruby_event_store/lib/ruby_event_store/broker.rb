# frozen_string_literal: true

module RubyEventStore
  class Broker
    def initialize(subscriptions:, dispatcher:)
      @subscriptions = subscriptions
      @dispatcher = dispatcher
    end

    def call(event, record)
      subscribers = subscriptions.all_for(event.event_type)
      subscribers.each do |subscriber|
        dispatcher.call(subscriber, event, record)
      end
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

    private
    attr_reader :subscriptions, :dispatcher

    def verify_subscription(subscriber)
      raise SubscriberNotExist, "subscriber must be first argument or block" unless subscriber
      raise InvalidHandler.new("Handler #{subscriber} is invalid for dispatcher #{dispatcher}") unless dispatcher.verify(subscriber)
    end
  end
end
