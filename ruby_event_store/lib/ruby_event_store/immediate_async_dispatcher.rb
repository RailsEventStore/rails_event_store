module RubyEventStore
  class ImmediateAsyncDispatcher
    def initialize(scheduler:)
      @scheduler = scheduler
    end

    def call(subscriber, _, serialized_event)
      @scheduler.call(subscriber, serialized_event)
    end

    def verify(subscriber)
      @scheduler.verify(subscriber)
    end
  end
end
