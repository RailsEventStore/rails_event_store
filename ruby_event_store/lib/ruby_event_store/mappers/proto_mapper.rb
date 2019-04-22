module RubyEventStore
  module Mappers
    class ProtoMapper
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
