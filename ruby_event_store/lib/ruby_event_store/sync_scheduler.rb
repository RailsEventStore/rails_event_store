# frozen_string_literal: true

module RubyEventStore
  class SyncScheduler
    def call(subscriber, event, _)
      subscriber.call(event)
    end

    def verify(subscriber)
      subscriber.respond_to?(:call)
    end
  end
end
