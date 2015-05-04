require 'securerandom'

module RailsEventStore
  class Event

    def initialize(event_data={})
      @event_type = event_data.fetch(:event_type, event_name)
      @event_id   = event_data.fetch(:event_id, generate_id).to_s
      @metadata   = event_data.fetch(:metadata, {})
      @data       = event_data.fetch(:data, {})
    end
    attr_reader :event_type, :event_id, :metadata, :data

    def to_h
      {
          event_type: event_type,
          event_id:   event_id,
          metadata:   metadata.merge!(publish_time),
          data:       data
      }
    end

    private

    def publish_time
      { published_at: Time.now.utc }
    end

    def generate_id
      SecureRandom.uuid
    end

    def event_name
      self.class.name
    end
  end
end
