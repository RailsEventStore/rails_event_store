module RubyEventStore
  module Mappers
    class SerializedRecordMapper
      def dump(item)
        SerializedRecord.new(
          event_id:   item.event_id,
          metadata:   item.metadata,
          data:       item.data,
          event_type: item.event_type
        )
      end

      def load(serialized_record)
        TransformationItem.new(
          event_id:   serialized_record.event_id,
          metadata:   serialized_record.metadata,
          data:       serialized_record.data,
          event_type: serialized_record.event_type
        )
      end
    end
  end
end
