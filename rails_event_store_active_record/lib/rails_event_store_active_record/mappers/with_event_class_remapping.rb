module RailsEventStoreActiveRecord
  module Mappers
    class WithEventClassRemapping < YAML

      def initialize(events_class_remapping: {})
        super()
        @events_class_remapping = events_class_remapping
      end

      def serialized_record_to_event(record)
        event_type = events_class_remapping.fetch(record.event_type) { record.event_type }
        event_type.constantize.new(
          event_id: record.id,
          metadata: serializer.load(record.metadata),
          data:     serializer.load(record.data)
        )
      end

      private

      attr_reader :events_class_remapping
    end
  end
end
