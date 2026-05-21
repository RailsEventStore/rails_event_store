# frozen_string_literal: true

module RubyEventStore
  class SyncScheduler
    def call(subscriber, event, _)
      if Class === subscriber
        Deprecations.warn(:class_subscriber)
        subscriber = subscriber.new
      end
      subscriber.call(event)
    end

    def verify(subscriber)
      if Class === subscriber
        Deprecations.warn(:class_subscriber)
        begin
          subscriber.new.respond_to?(:call)
        rescue ArgumentError
          false
        end
      else
        subscriber.respond_to?(:call)
      end
    end
  end
end
