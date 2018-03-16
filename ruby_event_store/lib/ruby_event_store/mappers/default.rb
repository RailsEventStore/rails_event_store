require 'yaml'
require 'active_support'

module RubyEventStore
  module Mappers
    class Default
      def initialize(serializer: YAML, events_class_remapping: {})
        @serializer = serializer
        @events_class_remapping = events_class_remapping
      end

      def event_to_serialized_record(domain_event)
        SerializedRecord.new(
          event_id:         domain_event.event_id,
          metadata:   @serializer.dump(domain_event.metadata),
          data:       @serializer.dump(domain_event.data),
          event_type: domain_event.class.name
        )
      end

      def serialized_record_to_event(record)
        event_type = @events_class_remapping.fetch(record.event_type) { record.event_type }
        ActiveSupport::Inflector.constantize(event_type).new(
          event_id: record.event_id,
          metadata: @serializer.load(record.metadata),
          data:     @serializer.load(record.data)
        )
      end

      def add_metadata(event, key, value)
        event.metadata[key.to_sym] = value
      end

      def get_metadata(event, key)
        event.metadata[key.to_sym]
      end
    end
  end
end
