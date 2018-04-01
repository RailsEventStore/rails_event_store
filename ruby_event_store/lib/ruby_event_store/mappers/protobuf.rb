module RubyEventStore
  class Proto < RubyEventStore::Event
    def initialize(event_id: SecureRandom.uuid, metadata: {}, data:)
      @event_id = event_id
      @metadata = metadata
      @data     = data
    end

    def type
      data.class.descriptor.name
    end

    def encode_with(coder)
      coder['event_id']   = event_id
      coder['metadata']   = metadata
      coder['data.proto'] = data.class.encode(data)
      coder['data.type']  = type
    end

    def init_with(coder)
      @event_id = coder['event_id']
      @metadata = coder['metadata']
      @data = pool.lookup(coder['data.type']).msgclass.decode(coder['data.proto'])
    end

    private

    def pool
      Google::Protobuf::DescriptorPool.generated_pool
    end
  end

  module Mappers
    class Protobuf
      def initialize(events_class_remapping: {})
        @events_class_remapping = events_class_remapping
      end

      def event_to_serialized_record(domain_event)
        SerializedRecord.new(
          event_id:   domain_event.event_id,
          metadata:   YAML.dump(domain_event.metadata),
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
          metadata: YAML.load(record.metadata)
        )
      end

      private

      attr_reader :event_id_getter, :events_class_remapping
    end
  end
end