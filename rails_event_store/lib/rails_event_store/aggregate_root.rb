module RailsEventStore
  module AggregateRoot
    def generate_uuid
      SecureRandom.uuid
    end

    def apply(event)
      public_send("apply_#{StringUtils.underscore(event.class.name)}")
    end
  end
end
