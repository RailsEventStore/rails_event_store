require 'yaml'

module RubyEventStore
  module Mappers
    class Default
      def initialize(serializer: YAML, event_builder: TypeToClass.new, events_class_remapping: {})
        @serializer = serializer
        @event_builder = events_class_remapping.empty? ? event_builder : BackwardCompatibleBuilderWithEventRemapping.new(events_class_remapping)
      end

      def event_to_serialized_record(domain_event)
        SerializedRecord.new(
          event_id:   domain_event.event_id,
          metadata:   serializer.dump(domain_event.metadata.to_h),
          data:       serializer.dump(domain_event.data),
          event_type: domain_event.type
        )
      end

      def serialized_record_to_event(record)
        event_builder.call(record.event_type).new(
          event_id: record.event_id,
          metadata: TransformKeys.symbolize(serializer.load(record.metadata)),
          data:     serializer.load(record.data)
        )
      end

      private
      attr_reader :serializer, :event_builder
    end
  end
end
