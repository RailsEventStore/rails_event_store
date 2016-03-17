require 'active_support/inflector'

module AggregateRoot
  module Base
    attr_reader :id

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
    attr_writer :id

    def apply_event(event)
      send("apply_#{event.class.name.underscore.gsub('/', '_')}", event)
    end

    def generate_uuid
      SecureRandom.uuid
    end
  end
end
