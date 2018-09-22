module RailsEventStore
  class ActiveJobScheduler
    def call(klass, serialized_event)
      klass.perform_later(serialized_event.to_h)
    end

    def verify(subscriber)
      Class === subscriber && subscriber < ActiveJob::Base
    end
  end
end
