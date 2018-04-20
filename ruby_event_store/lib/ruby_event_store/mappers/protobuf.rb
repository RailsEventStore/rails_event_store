module RubyEventStore
  class Proto < RubyEventStore::Event
    def initialize(event_id: SecureRandom.uuid, metadata: {}, data:)
      @event_id = event_id
      @metadata = Metadata.new(metadata.to_h)
      @data     = data
    end

    def type
      data.class.descriptor.name
    end

    def encode_with(coder)
      coder['event_id']   = event_id
      coder['metadata']   = ProtobufNestedStruct::HashMapStringValue.dump(metadata.each_with_object({}){|(k,v),h| h[k.to_s] =v })
      coder['data.proto'] = data.class.encode(data)
      coder['data.type']  = type
    end

    def init_with(coder)
      @event_id = coder['event_id']
      @metadata = Metadata.new
      ProtobufNestedStruct::HashMapStringValue.load(coder['metadata']).each_with_object(@metadata){|(k,v),meta| meta[k.to_sym] = v }
      @data = pool.lookup(coder['data.type']).msgclass.decode(coder['data.proto'])
    end

    def ==(other_event)
      other_event.instance_of?(self.class) &&
        other_event.event_id.eql?(event_id) &&
        other_event.data == data # https://github.com/google/protobuf/issues/4455
    end

    private

    def pool
      Google::Protobuf::DescriptorPool.generated_pool
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
          metadata:   ProtobufNestedStruct::HashMapStringValue.dump(domain_event.metadata.each_with_object({}){|(k,v),h| h[k.to_s] =v }),
          data:       domain_event.data.class.encode(domain_event.data),
          event_type: domain_event.type
        )
      end

      def serialized_record_to_event(record)
        event_type = events_class_remapping.fetch(record.event_type) { record.event_type }
        data = Google::Protobuf::DescriptorPool.generated_pool.lookup(event_type).msgclass.decode(record.data)
        Proto.new(
          event_id: record.event_id,
          data: data,
          metadata: {},
        ).tap do |p|
          ProtobufNestedStruct::HashMapStringValue.load(record.metadata).each_with_object(p.metadata) {|(k, v), meta| meta[k.to_sym] = v}
        end
      end

      private

      attr_reader :event_id_getter, :events_class_remapping

      def require_optional_dependency
        require 'protobuf_nested_struct'
      rescue LoadError
        raise LoadError, "cannot load such file -- protobuf_nested_struct. Add protobuf_nested_struct gem to Gemfile"
      end
    end
  end
end