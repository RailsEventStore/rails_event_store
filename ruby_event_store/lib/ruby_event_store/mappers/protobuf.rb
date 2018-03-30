module RubyEventStore
  class Proto < RubyEventStore::Event
    def initialize(event_id: SecureRandom.uuid, metadata: nil, data: nil)
      @event_id = event_id.to_s
      @metadata = metadata.to_h
      @data     = data
    end

    def type
      data.class.name
    end
  end

  module Mappers
    class Protobuf
      def initialize(event_id_getter: :event_id, events_class_remapping: {})
        @event_id_getter = event_id_getter
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
        data = Object.const_get(event_type).decode(record.data)
        Proto.new(
          event_id: record.event_id,
          data: data,
          metadata: YAML.load(record.metadata)
        )
      end

      def add_metadata(event, key, value)
        setter = "#{key}="
        if event.respond_to?(setter)
          event.public_send(setter, value)
        end
      end

      private

      attr_reader :event_id_getter, :events_class_remapping
    end
  end
end