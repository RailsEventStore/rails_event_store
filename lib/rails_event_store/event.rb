require 'securerandom'

module RailsEventStore
  class Event
    include ActiveModel::Model

    attr_reader :metadata, :event_id, :event_type

    def initialize(data = {})
      super

      @event_id   ||= generate_event_id
      @event_type ||= generate_event_type
      @metadata   ||= {}
      @metadata.merge!(publish_time)
    end

    def data
      attributes_except :metadata, :event_id, :event_type
    end

    def to_h
      {
        event_type: event_type,
        event_id:   event_id,
        metadata:   metadata,
        data:       data
      }
    end

    private

    def attributes_except(*attrs)
      as_json.reject { |k, _| attrs.include?(k.to_sym) }.with_indifferent_access
    end

    def publish_time
      { published_at: Time.now.utc }
    end

    def generate_event_id
      SecureRandom.uuid
    end

    def generate_event_type
      self.class.name
    end

  end
end
