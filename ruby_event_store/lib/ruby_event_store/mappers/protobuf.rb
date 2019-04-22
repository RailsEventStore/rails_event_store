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
      include PipelineMapper

      def initialize(events_class_remapping: {})
        @pipeline = Pipeline.new(
          to_domain_event: DomainEventProtoMapper.new,
          transformations: [
            ProtoMapper.new,
            EventClassRemapper.new(events_class_remapping),
            ProtobufNestedStructMetadataMapper.new,
          ]
        )
      end
    end
  end
end
