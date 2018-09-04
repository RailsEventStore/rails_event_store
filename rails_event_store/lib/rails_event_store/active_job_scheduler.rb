module RailsEventStore
  class ActiveJobScheduler
    def call(klass, serialized_event)
      klass.perform_later(serialized_event.to_h)
    end

    def verify(subscriber)
      raise InvalidHandler.new("#{subscriber.inspect} is not a class inheriting from ActiveJob::Base") unless Class === subscriber && !!(subscriber < ActiveJob::Base)
    end
  end
end
