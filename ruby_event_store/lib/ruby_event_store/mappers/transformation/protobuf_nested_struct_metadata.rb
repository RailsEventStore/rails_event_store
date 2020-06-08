# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      class ProtobufNestedStructMetadata
        def initialize
          require_optional_dependency
        end

        def dump(item)
          metadata = ProtobufNestedStruct::HashMapStringValue.dump(item.metadata)
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
end
