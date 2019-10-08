# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      class DomainEvent
        def dump(domain_event)
          Record.new(
            event_id:   domain_event.event_id,
            metadata:   domain_event.metadata.to_h.reject { |k, _| k.eql?(:timestamp) },
            data:       domain_event.data,
            event_type: domain_event.event_type,
            timestamp:  domain_event.timestamp,
          )
        end

        def load(record)
          Object.const_get(record.event_type).new(
            event_id: record.event_id,
            metadata: record.metadata.merge(timestamp: record.timestamp),
            data:     record.data,
          )
        end
      end
    end
  end
end
