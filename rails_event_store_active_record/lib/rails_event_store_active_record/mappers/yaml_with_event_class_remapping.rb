module RailsEventStoreActiveRecord
  module Mappers
    class YAMLWithEventClassRemapping

      def initialize(serializer: ::YAML, events_class_remapping: {})
        @serializer             = serializer
        @events_class_remapping = events_class_remapping
      end

      def create_event(event)
        Event.create!(
          id:         event.event_id,
          data:       serializer.dump(event.data),
          metadata:   serializer.dump(event.metadata),
          event_type: event.class,
        )
      end

      def build_event(record)
        return nil unless record
        event_type = events_class_remapping.fetch(record.event.event_type) { record.event.event_type }
        event_type.constantize.new(
          event_id: record.event.id,
          metadata: serializer.load(record.event.metadata),
          data:     serializer.load(record.event.data)
        )
      end

      private

      attr_reader :serializer, :events_class_remapping
    end
  end
end
