# frozen_string_literal: true

module RubyEventStore
  class Broker
    def initialize(subscriptions:, dispatcher:, event_type_resolver: EventTypeResolver.new)
      @subscriptions = subscriptions
      @dispatcher = dispatcher
      @event_type_resolver = event_type_resolver
    end

    def call(event, record)
      subscribers = subscriptions.all_for(event.event_type)
      subscribers.each { |subscriber| dispatcher.call(subscriber, event, record) }
    end

    def add_subscription(subscriber, event_types)
      verify_subscription(subscriber)
      subscriptions.add_subscription(subscriber, event_types.map { |type| event_type_resolver.call(type) })
    end

    def add_global_subscription(subscriber)
      verify_subscription(subscriber)
      subscriptions.add_global_subscription(subscriber)
    end

    def add_thread_subscription(subscriber, event_types)
      verify_subscription(subscriber)
      subscriptions.add_thread_subscription(subscriber, event_types.map { |type| event_type_resolver.call(type) })
    end

    def add_thread_global_subscription(subscriber)
      verify_subscription(subscriber)
      subscriptions.add_thread_global_subscription(subscriber)
    end

    def all_subscriptions_for(event_type)
      subscriptions.all_for(event_type_resolver.call(event_type))
    end

    private

    attr_reader :dispatcher, :subscriptions, :event_type_resolver

    def verify_subscription(subscriber)
      raise SubscriberNotExist, "subscriber must be first argument or block" unless subscriber
      unless dispatcher.verify(subscriber)
        raise InvalidHandler.new("Handler #{subscriber} is invalid for dispatcher #{dispatcher}")
      end
    end
  end
end
