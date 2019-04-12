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
    class DomainEventProtoMapper
      def dump(domain_event)
        {
          event_id:   domain_event.event_id,
          metadata:   domain_event.metadata.to_h,
          data:       domain_event.data,
          event_type: domain_event.type
        }
      rescue NoMethodError
        raise ProtobufEncodingFailed
      end

      def load(item)
        Proto.new(
          event_id: item.fetch(:event_id),
          data:     load_data(item.fetch(:event_type), item.fetch(:data)),
          metadata: load_metadata(item.fetch(:metadata))
        )
      end

      def load_metadata(protobuf_metadata)
        TransformKeys.symbolize(ProtobufNestedStruct::HashMapStringValue.load(protobuf_metadata))
      end

      def load_data(event_type, protobuf_data)
        Google::Protobuf::DescriptorPool.generated_pool.lookup(event_type).msgclass.decode(protobuf_data)
      end
    end

    class SerializedRecordProtoMapper
      def dump(item)
        SerializedRecord.new(
          event_id:   item.fetch(:event_id),
          metadata:   encode_metadata(item.fetch(:metadata)),
          data:       encode_data(item.fetch(:data)),
          event_type: item.fetch(:event_type)
        )
      end

      def load(serialized_record)
        {
          event_id:   serialized_record.event_id,
          metadata:   serialized_record.metadata,
          data:       serialized_record.data,
          event_type: serialized_record.event_type
        }
      end

      private
      def encode_data(data)
        begin
          data.class.encode(data)
        rescue NoMethodError
          raise ProtobufEncodingFailed
        end
      end

      def encode_metadata(metadata)
        ProtobufNestedStruct::HashMapStringValue.dump(TransformKeys.stringify(metadata))
      end
    end

    class Protobuf
      include PipelineMapper

      def initialize(events_class_remapping: {})
        require_optional_dependency
        @pipeline = Pipeline.new([
          DomainEventProtoMapper.new,
          EventClassRemapper.new(events_class_remapping),
          SerializedRecordProtoMapper.new
        ])
      end

      def require_optional_dependency
        require 'protobuf_nested_struct'
      rescue LoadError
        raise LoadError, "cannot load such file -- protobuf_nested_struct. Add protobuf_nested_struct gem to Gemfile"
      end
    end
  end
end
