module RailsEventStoreActiveRecord
  module Mappers
    class YAML
      def initialize
        @serializer = ::YAML
      end

      def event_to_serialized_record(event)
        RubyEventStore::SerializedRecord.new(
          id:         event.event_id,
          metadata:   serializer.dump(event.metadata),
          data:       serializer.dump(event.data),
          event_type: event.class
        )
      end

      def serialized_record_to_event(record)
        record.event_type.constantize.new(
          event_id: record.id,
          metadata: serializer.load(record.metadata),
          data:     serializer.load(record.data)
        )
      end

      private

      attr_reader :serializer
    end
  end
end
