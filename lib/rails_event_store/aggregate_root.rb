module RailsEventStore
  module AggregateRoot
    def generate_uuid
      SecureRandom.uuid
    end

    def apply(event)
      public_send("apply_#{StringUtils.underscore(event.class.name)}")
      unpublished_events << event
    end

    def unpublished_events
      @unpublished_events ||= []
    end
  end
end
