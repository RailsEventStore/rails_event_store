module RailsEventStoreActiveRecord
  module Mappers
    class YAML
      def initialize
        @serializer = ::YAML
      end

      def event_to_record(event)
        Event.new(
          id:         event.event_id,
          data:       serializer.dump(event.data),
          metadata:   serializer.dump(event.metadata),
          event_type: event.class
        )
      end

      def record_to_event(record)
        record.event.event_type.constantize.new(
          event_id: record.event.id,
          metadata: serializer.load(record.event.metadata),
          data:     serializer.load(record.event.data)
        )
      end

      private

      attr_reader :serializer
    end
  end
end
