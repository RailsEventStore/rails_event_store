# frozen_string_literal: true

module RubyEventStore
  class Broker
    def initialize(subscriptions:, dispatcher:)
      @subscriptions = subscriptions
      @dispatcher = dispatcher
    end

    def call(event, serialized_event)
      subscribers = subscriptions.all_for(event.type)
      subscribers.each do |subscriber|
        dispatcher.call(subscriber, event, serialized_event)
      end
    end

    def add_subscription(subscriber, event_types = [ANY_EVENT_TYPE])
      verify_subscription(subscriber)
      subscriptions.add(subscriber, event_types)
    end

    private
    attr_reader :subscriptions, :dispatcher

    def verify_subscription(subscriber)
      raise SubscriberNotExist, "subscriber must be first argument or block" unless subscriber
      raise InvalidHandler.new("Handler #{subscriber} is invalid for dispatcher #{dispatcher}") unless dispatcher.verify(subscriber)
    end
  end
end
