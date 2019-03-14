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
        event_builder.call(record.event_type).call(
          event_id: record.event_id,
          metadata: TransformKeys.symbolize(serializer.load(record.metadata)),
          data:     serializer.load(record.data)
        )
      end

      private
      attr_reader :serializer, :event_builder

      class BackwardCompatibleBuilderWithEventRemapping
        def initialize(events_class_remapping)
          unless events_class_remapping.empty?
            warn <<~EOW
              events_class_remapping is deprecated. Provide custom event builder instead.
            EOW
          end
          @events_class_remapping = events_class_remapping
        end

        def call(event_type)
          type = @events_class_remapping.fetch(event_type) { event_type }
          ->(args) { Object.const_get(type).new(args) }
        end
      end
    end
  end
end
