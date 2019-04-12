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
          event_id:   item.fetch(:event_id),
          metadata:   serializer.dump(item.fetch(:metadata)),
          data:       serializer.dump(item.fetch(:data)),
          event_type: item.fetch(:event_type)
        )
      end

      def load(serialized_record)
        {
          event_id:   serialized_record.event_id,
          metadata:   serializer.load(serialized_record.metadata),
          data:       serializer.load(serialized_record.data),
          event_type: serialized_record.event_type
        }
      end
    end
  end
end
