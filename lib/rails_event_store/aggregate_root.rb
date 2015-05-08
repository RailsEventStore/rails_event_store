module RailsEventStore
  module AggregateRoot
    def generate_uuid
      SecureRandom.uuid
    end

    def apply(event)
      apply_event(event, true)
    end

    def apply_old_event(event)
      apply_event(event, false)
    end

    def apply_event(event, new)
      public_send("apply_#{StringUtils.underscore(event.event_type)}")
      unpublished_events << event if new
    end

    def unpublished_events
      @unpublished_events ||= []
    end
  end
end
