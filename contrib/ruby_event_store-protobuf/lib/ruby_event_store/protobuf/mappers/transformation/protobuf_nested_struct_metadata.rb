# frozen_string_literal: true

module RubyEventStore
  module Protobuf
    module Mappers
      module Transformation
        class ProtobufNestedStructMetadata
          def dump(record)
            Record.new(
              event_id: record.event_id,
              event_type: record.event_type,
              data: record.data,
              metadata:
                ProtobufNestedStruct::HashMapStringValue.dump(record.metadata),
              timestamp: record.timestamp,
              valid_at: record.valid_at
            )
          end

          def load(record)
            RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new.load(
              Record.new(
                event_id: record.event_id,
                event_type: record.event_type,
                data: record.data,
                metadata:
                  ProtobufNestedStruct::HashMapStringValue.load(
                    record.metadata
                  ),
                timestamp: record.timestamp,
                valid_at: record.valid_at
              )
            )
          end
        end
      end
    end
  end
end
