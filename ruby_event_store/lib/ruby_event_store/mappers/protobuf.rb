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
    class Protobuf
      def initialize(events_class_remapping: {})
        require_optional_dependency
        @events_class_remapping = events_class_remapping
      end

      def event_to_serialized_record(domain_event)
        SerializedRecord.new(
          event_id:   domain_event.event_id,
          metadata:   ProtobufNestedStruct::HashMapStringValue.dump(domain_event.metadata.each_with_object({}) {|(k, v), h| h[k.to_s] = v}),
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
        ProtobufNestedStruct::HashMapStringValue.load(protobuf_metadata).each_with_object({}) do |(k, v), meta|
          meta[k.to_sym] = v
        end
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
