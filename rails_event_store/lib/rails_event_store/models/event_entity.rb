require 'virtus'
require 'securerandom'

module RailsEventStore
  module Models
    class EventEntity
      include Virtus.model

      attribute :stream,      String
      attribute :event_type,  String
      attribute :event_id,    String, default: SecureRandom.uuid
      attribute :metadata,    Hash
      attribute :data,        Hash

      def validate!
        [self.stream, self.event_type, self.event_id, self.data].any? { |var| var.nil? || var.empty? }
      end

    end
  end
end