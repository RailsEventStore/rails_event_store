# frozen_string_literal: true

module RubyEventStore
  class SyncScheduler
    DEPRECATION_MESSAGE = <<~EOW
      DEPRECATION WARNING: Passing a class as a subscriber is deprecated and will be removed in the next major release.
      Pass an instance or lambda instead, e.g. subscribe(MyHandler.new, to: [MyEvent]).
    EOW

    def call(subscriber, event, _)
      if Class === subscriber
        warn DEPRECATION_MESSAGE
        subscriber = subscriber.new
      end
      subscriber.call(event)
    end

    def verify(subscriber)
      if Class === subscriber
        warn DEPRECATION_MESSAGE
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
