module RubyEventStore
  class Proto < RubyEventStore::Event
    def type
      data.class.descriptor.name
    end

    def ==(other_event)
      other_event.instance_of?(self.class) &&
        other_event.event_id.eql?(event_id) &&
        other_event.data == data # https://github.com/google/protobuf/issues/4455
    end
  end

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

    class DomainEventProtoMapper
      def dump(domain_event)
        TransformationItem.new(
          event_id:   domain_event.event_id,
          metadata:   domain_event.metadata,
          data:       domain_event.data,
          event_type: domain_event.type
        )
      rescue NoMethodError
        raise ProtobufEncodingFailed
      end

      def load(item)
        Proto.new(
          event_id: item.event_id,
          data:     item.data,
          metadata: item.metadata
        )
      end

    end

    class SerializedRecordProtoMapper
      def dump(item)
        SerializedRecord.new(
          event_id:   item.event_id,
          metadata:   item.metadata,
          data:       item.data,
          event_type: item.event_type
        )
      end

      def load(serialized_record)
        TransformationItem.new(
          event_id:   serialized_record.event_id,
          metadata:   serialized_record.metadata,
          data:       serialized_record.data,
          event_type: serialized_record.event_type
        )
      end
    end

    class Protobuf
      include PipelineMapper

      def initialize(events_class_remapping: {})
        require_optional_dependency
        @pipeline = Pipeline.new(
          to_domain_event: DomainEventProtoMapper.new,
          to_serialized_record: SerializedRecordProtoMapper.new,
          transformations: [
            ProtoMapper.new,
            EventClassRemapper.new(events_class_remapping),
            SymbolizeMetadataKeys.new,
            StringifyMetadataKeys.new,
            ProtobufNestedStructMetadataMapper.new,
          ]
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
