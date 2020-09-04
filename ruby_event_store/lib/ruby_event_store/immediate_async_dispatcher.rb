# frozen_string_literal: true

module RubyEventStore
  class ImmediateAsyncDispatcher
    def initialize(scheduler:)
      @scheduler = scheduler
    end

    def call(subscriber, _, serialized_record)
      @scheduler.call(subscriber, serialized_record)
    end

    def verify(subscriber)
      @scheduler.verify(subscriber)
    end
  end
end
