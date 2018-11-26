module RubyEventStore
  module TransformKeys
    private
    def stringify_keys(data)
      transform_keys(data) {|k| k.to_s}
    end
    def symbolize_keys(data)
      transform_keys(data) {|k| k.to_sym}
    end

    def transform_keys(data, &block)
      data.each_with_object({}) do |(k, v), h|
        h[yield(k)] = case v
          when Hash
            transform_keys(v, &block)
          when Array
            v.map{|i| Hash === i ? transform_keys(i, &block) : i}
          else
            v
        end
      end
    end
  end

  class Proto < RubyEventStore::Event
    include TransformKeys

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
    class Protobuf
      include TransformKeys

      def initialize(events_class_remapping: {})
        require_optional_dependency
        @events_class_remapping = events_class_remapping
      end

      def event_to_serialized_record(domain_event)
        SerializedRecord.new(
          event_id:   domain_event.event_id,
          metadata:   ProtobufNestedStruct::HashMapStringValue.dump(stringify_keys(domain_event.metadata)),
          data:       encode_data(domain_event.data),
          event_type: domain_event.type
        )
      end

      def serialized_record_to_event(record)
        event_type = events_class_remapping.fetch(record.event_type) { record.event_type }
        Proto.new(
          event_id: record.event_id,
          data:     load_data(event_type, record.data),
          metadata: load_metadata(record.metadata)
        )
      end

      private

      attr_reader :event_id_getter, :events_class_remapping

      def load_metadata(protobuf_metadata)
        symbolize_keys(ProtobufNestedStruct::HashMapStringValue.load(protobuf_metadata))
      end

      def load_data(event_type, protobuf_data)
        Google::Protobuf::DescriptorPool.generated_pool.lookup(event_type).msgclass.decode(protobuf_data)
      end

      def encode_data(domain_event_data)
        begin
          domain_event_data.class.encode(domain_event_data)
        rescue NoMethodError
          raise ProtobufEncodingFailed
        end
      end

      def require_optional_dependency
        require 'protobuf_nested_struct'
      rescue LoadError
        raise LoadError, "cannot load such file -- protobuf_nested_struct. Add protobuf_nested_struct gem to Gemfile"
      end
    end
  end
end
