# frozen_string_literal: true

module RailsEventStore
  module AsyncHandler
    class << self
      def with_defaults
        with
      end

      def with(event_store: Rails.configuration.event_store, event_store_locator: nil, serializer: RubyEventStore::Serializers::YAML)
        Module.new do
          define_method :perform do |payload|
            event_store = event_store_locator.call if event_store_locator
            record = AsyncHandler.event_from_payload(payload, event_store, serializer)
            super(record)
          end
        end
      end

      def prepended(host_class)
        host_class.prepend with_defaults
      end

      # @return [Event] an event as deserialized from the payload
      def event_from_payload(payload, event_store, serializer)
        return payload if payload.kind_of?(RailsEventStore::Event)

        payload_hash = payload.to_h.symbolize_keys
        event_store.deserialize(serializer: serializer, **payload_hash)
      end
    end
  end

  module CorrelatedHandler
    def perform(event)
      Rails.configuration.event_store.with_metadata(
        correlation_id: event.metadata[:correlation_id],
        causation_id:   event.event_id
      ) do
        super
      end
    end
  end
end
