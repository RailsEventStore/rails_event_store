# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      class ProtobufEncoder
        def dump(item)
          item.merge(data: encode_data(item.data))
        end

        def load(item)
          item.merge(data: load_data(item.event_type, item.data))
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
