module RailsEventStore
  module AggregateRoot
    def apply(event)
      apply_event(event)
      unpublished_events << event
    end

    def apply_old_event(event)
      apply_event(event)
    end

    def unpublished_events
      @unpublished_events ||= []
    end

    private

    def apply_event(event)
      public_send("apply_#{StringUtils.underscore(event.event_type)}")
    end

    def generate_uuid
      SecureRandom.uuid
    end
  end
end
