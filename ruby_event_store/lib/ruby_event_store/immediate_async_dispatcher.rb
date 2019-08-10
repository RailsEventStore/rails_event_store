# frozen_string_literal: true

module RubyEventStore
  class ImmediateAsyncDispatcher
    def initialize(scheduler:)
      @scheduler = scheduler
    end

    def call(subscription, _, serialized_event)
      @scheduler.call(subscription, serialized_event)
    end

    def verify(subscriber)
      @scheduler.verify(subscriber)
    end
  end
end
