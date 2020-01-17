# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      class DomainEvent
        def dump(domain_event)
          Item.new(
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
        rescue NameError => e
          raise e unless ENV.fetch('RAILS_ENV_STORE_ALLOW_MISSING_EVENTS', false)
        end
      end
    end
  end
end
