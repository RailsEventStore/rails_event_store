require 'yaml'

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
          metadata:   serializer.dump(domain_event.metadata.to_h),
          data:       serializer.dump(domain_event.data),
          event_type: domain_event.class.name
        )
      end

      def serialized_record_to_event(record)
        event_type = events_class_remapping.fetch(record.event_type) { record.event_type }
        Object.const_get(event_type).new(
          event_id: record.event_id,
          metadata: TransformKeys.symbolize(serializer.load(record.metadata)),
          data:     serializer.load(record.data)
        )
      end

      private
      attr_reader :serializer, :events_class_remapping
    end
  end
end
