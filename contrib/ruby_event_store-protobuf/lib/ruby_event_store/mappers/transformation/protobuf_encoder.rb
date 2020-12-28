# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      class ProtobufEncoder
        def dump(record)
          Record.new(
            event_id:   record.event_id,
            event_type: record.event_type,
            data:       encode_data(record.data),
            metadata:   record.metadata,
            timestamp:  record.timestamp,
            valid_at:   record.valid_at,
          )
        end

        def load(record)
          Record.new(
            event_id:   record.event_id,
            event_type: record.event_type,
            data:       load_data(record.event_type, record.data),
            metadata:   record.metadata,
            timestamp:  record.timestamp,
            valid_at:   record.valid_at,
          )
        end

        private
        def encode_data(data)
          begin
            data.class.encode(data)
          rescue NoMethodError
            raise ProtobufEncodingFailed
          end
        end

        def load_data(event_type, protobuf_data)
          Google::Protobuf::DescriptorPool.generated_pool.lookup(event_type).msgclass.decode(protobuf_data)
        end
      end
    end
  end
end
