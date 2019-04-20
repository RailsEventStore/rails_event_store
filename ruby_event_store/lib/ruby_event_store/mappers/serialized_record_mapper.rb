require 'yaml'

module RubyEventStore
  module Mappers
    class SerializedRecordMapper
      def initialize(serializer: YAML)
        @serializer = serializer
      end
      attr_reader :serializer

      def dump(item)
        SerializedRecord.new(
          event_id:   item.event_id,
          metadata:   serializer.dump(item.metadata),
          data:       serializer.dump(item.data),
          event_type: item.event_type
        )
      end

      def load(serialized_record)
        TransformationItem.new(
          event_id:   serialized_record.event_id,
          metadata:   serializer.load(serialized_record.metadata),
          data:       serializer.load(serialized_record.data),
          event_type: serialized_record.event_type
        )
      end
    end
  end
end
