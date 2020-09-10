# frozen_string_literal: true

module RubyEventStore
  class ImmediateAsyncDispatcher
    def initialize(scheduler:)
      @scheduler = scheduler
    end

    def call(subscriber, _, record)
      @scheduler.call(subscriber, record)
    end

    def verify(subscriber)
      @scheduler.verify(subscriber)
    end
  end
end
