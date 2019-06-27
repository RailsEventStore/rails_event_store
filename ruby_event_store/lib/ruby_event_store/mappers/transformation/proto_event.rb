# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      class ProtoEvent < DomainEvent
        def load(item)
          Proto.new(
            event_id: item.event_id,
            data:     item.data,
            metadata: item.metadata
          )
        end
      end
    end
  end
end
