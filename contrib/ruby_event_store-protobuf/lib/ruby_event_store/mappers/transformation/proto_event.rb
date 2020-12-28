# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      class ProtoEvent < DomainEvent
        def load(record)
          Proto.new(
            event_id:  record.event_id,
            data:      record.data,
            metadata:  record.metadata.merge(
              timestamp: record.timestamp,
              valid_at:  record.valid_at,
            ),
          )
        end
      end
    end
  end
end
