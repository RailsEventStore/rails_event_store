# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      class DomainEvent
        def dump(domain_event)
          metadata = domain_event.metadata.dup.to_h
          timestamp = metadata.delete(:timestamp)
          valid_at = metadata.delete(:valid_at)
          Record.new(
            event_id: domain_event.event_id,
            metadata: metadata,
            data: domain_event.data,
            event_type: domain_event.event_type,
            timestamp: timestamp,
            valid_at: valid_at
          )
        end

        def load(record)
          Object
            .const_get(record.event_type)
            .new(
              event_id: record.event_id,
              data: record.data,
              metadata: record.metadata.merge(timestamp: record.timestamp, valid_at: record.valid_at)
            )
        rescue NameError
          Event.new(
            event_id: record.event_id,
            data: record.data,
            metadata:
              record.metadata.merge(
                timestamp: record.timestamp,
                valid_at: record.valid_at,
                event_type: record.event_type
              )
          )
        end
      end
    end
  end
end
