module RubyEventStore
  module Mappers
    class DomainEventProtoMapper < DomainEventMapper
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
