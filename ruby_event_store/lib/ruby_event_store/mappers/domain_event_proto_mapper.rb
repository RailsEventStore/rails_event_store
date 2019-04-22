module RubyEventStore
  module Mappers
    class DomainEventProtoMapper
      def dump(domain_event)
        TransformationItem.new(
          event_id:   domain_event.event_id,
          metadata:   domain_event.metadata,
          data:       domain_event.data,
          event_type: domain_event.type
        )
      rescue NoMethodError
        raise ProtobufEncodingFailed
      end

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
