module RubyEventStore
  module Mappers
    class DomainEventMapper
      def dump(domain_event)
        {
          event_id:   domain_event.event_id,
          metadata:   domain_event.metadata.to_h,
          data:       domain_event.data,
          event_type: domain_event.type
        }
      end

      def load(item)
        Object.const_get(item.fetch(:event_type)).new(
          event_id: item.fetch(:event_id),
          metadata: item.fetch(:metadata),
          data:     item.fetch(:data)
        )
      end
    end
  end
end
