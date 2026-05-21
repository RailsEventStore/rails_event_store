# frozen_string_literal: true

module RubyEventStore
  class SyncScheduler
    Deprecations.register(
      :class_subscriber,
      "Passing a class as a subscriber is deprecated and will be removed in the next major release.\n" \
      "Pass an instance or lambda instead, e.g. subscribe(MyHandler.new, to: [MyEvent])."
    )

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
