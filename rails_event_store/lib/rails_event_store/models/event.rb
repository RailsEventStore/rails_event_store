require 'securerandom'

module RailsEventStore
  module Models
    class Event

      def initialize(event_data)
        @event_type = event_data.fetch(:event_type, event_name)
        @event_id   = event_data.fetch(:event_id, generate_id).to_s
        @metadata   = event_data.fetch(:metadata, nil)
        @data       = event_data.fetch(:data, nil)
      end
      attr_reader :event_type, :event_id, :metadata, :data

      def validate!
        [event_type, event_id, data].each do |attribute|
          raise IncorrectStreamData if is_invalid?(attribute)
        end
      end

      def to_h
        {
            event_type: event_type,
            event_id: event_id,
            metadata: metadata,
            data: data
        }
      end

      private

      def is_invalid?(attribute)
        attribute.nil? || attribute.empty?
      end

      def generate_id
        SecureRandom.uuid
      end

      def event_name
        self.class.name
      end
    end
  end
end