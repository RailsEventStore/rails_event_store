# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      class ProtobufNestedStructMetadata
        def initialize
          require_optional_dependency
        end

        def dump(record)
          Record.new(
            event_id:   record.event_id,
            event_type: record.event_type,
            data:       record.data,
            metadata:   ProtobufNestedStruct::HashMapStringValue.dump(record.metadata),
            timestamp:  record.timestamp,
            valid_at:   record.valid_at,
          )
        end

        def load(record)
          SymbolizeMetadataKeys.new.load(
            Record.new(
              event_id:   record.event_id,
              event_type: record.event_type,
              data:       record.data,
              metadata:   ProtobufNestedStruct::HashMapStringValue.load(record.metadata),
              timestamp:  record.timestamp,
              valid_at:   record.valid_at,
            )
          )
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
