module RubyEventStore
  module Mappers
    class ProtobufNestedStructMetadataMapper
      def initialize(serializer = ProtobufNestedStruct::HashMapStringValue)
        @serializer = serializer
      end
      attr_reader :serializer

      def dump(item)
        stringify = StringifyMetadataKeys.new
        metadata = ProtobufNestedStruct::HashMapStringValue.dump(stringify.dump(item).metadata)
        item.merge(metadata: metadata)
      end

      def load(item)
        metadata = ProtobufNestedStruct::HashMapStringValue.load(item.metadata)
        symbolize = SymbolizeMetadataKeys.new
        symbolize.load(item.merge(metadata: metadata))
      end
    end
  end
end
