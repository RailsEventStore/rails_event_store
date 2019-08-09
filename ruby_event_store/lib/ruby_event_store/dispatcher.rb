# frozen_string_literal: true

module RubyEventStore
  class Dispatcher
    def call(subscription, event, _)
      subscription.call(event)
    end

    def verify(subscriber)
      begin
        subscriber_instance = Class === subscriber ? subscriber.new : subscriber
      rescue ArgumentError
        false
      else
        subscriber_instance.respond_to?(:call)
      end
    end
  end
end
