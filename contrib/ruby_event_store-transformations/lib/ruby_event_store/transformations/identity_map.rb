# frozen_string_literal: true

module RubyEventStore
  module Transformations
    class IdentityMap
      def initialize
        @identity_map = {}
      end

      def dump(domain_event)
        @identity_map[domain_event.event_id] = domain_event
        metadata = domain_event.metadata.to_h
        timestamp = metadata.delete(:timestamp)
        valid_at = metadata.delete(:valid_at)

        Record.new(
          event_id: domain_event.event_id,
          metadata: metadata,
          data: domain_event.data,
          event_type: domain_event.event_type,
          timestamp: timestamp,
          valid_at: valid_at,
        )
      end

      def load(record)
        @identity_map.fetch(record.event_id)
      end
    end
  end
end
