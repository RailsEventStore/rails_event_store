module RubyEventStore
  module Mappers
    class ProtobufNestedStructMetadataMapper
      def initialize
        require_optional_dependency
      end

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

      def require_optional_dependency
        require 'protobuf_nested_struct'
      rescue LoadError
        raise LoadError, "cannot load such file -- protobuf_nested_struct. Add protobuf_nested_struct gem to Gemfile"
      end
    end
  end
end
