module RailsEventStoreActiveRecord
  module Mappers
    class WithEventClassRemapping < YAML

      def initialize(events_class_remapping: {})
        super()
        @events_class_remapping = events_class_remapping
      end

      def build_event_entity(record)
        return nil unless record
        event_type = events_class_remapping.fetch(record.event.event_type) { record.event.event_type }
        event_type.constantize.new(
          event_id: record.event.id,
          metadata: serializer.load(record.event.metadata),
          data:     serializer.load(record.event.data)
        )
      end

      private

      attr_reader :events_class_remapping
    end
  end
end
