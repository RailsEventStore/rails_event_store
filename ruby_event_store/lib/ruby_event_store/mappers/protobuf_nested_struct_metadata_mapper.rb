module RubyEventStore
  module Mappers
    class ProtobufNestedStructMetadataMapper
      def initialize(serializer = ProtobufNestedStruct::HashMapStringValue)
        @serializer = serializer
      end
      attr_reader :serializer

      def dump(item)
        metadata = serializer.dump(item.metadata)
        item.merge(metadata: metadata)
      end

      def load(item)
        metadata = serializer.load(item.metadata)
        item.merge(metadata: metadata)
      end
    end
  end
end
