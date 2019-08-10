# frozen_string_literal: true

module RubyEventStore
  class ComposedDispatcher
    def initialize(*dispatchers)
      @dispatchers = dispatchers
    end

    def call(subscription, event, serialized_event)
      @dispatchers.each do |dispatcher|
        if dispatcher.verify(subscription.subscriber)
          dispatcher.call(subscription, event, serialized_event)
          break
        end
      end
    end

    def verify(subscriber)
      @dispatchers.any? do |dispatcher|
        dispatcher.verify(subscriber)
      end
    end
  end
end
