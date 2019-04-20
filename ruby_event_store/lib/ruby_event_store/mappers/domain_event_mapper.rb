module RubyEventStore
  module Mappers
    class DomainEventMapper
      def dump(domain_event)
        TransformationItem.new(
          event_id:   domain_event.event_id,
          metadata:   domain_event.metadata.to_h,
          data:       domain_event.data,
          event_type: domain_event.type
        )
      end

      def load(item)
        Object.const_get(item.event_type).new(
          event_id: item.event_id,
          metadata: item.metadata,
          data:     item.data
        )
      end
    end
  end
end
