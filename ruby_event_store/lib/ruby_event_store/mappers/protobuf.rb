# frozen_string_literal: true

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
    class Protobuf < PipelineMapper
      def initialize(events_class_remapping: {})
        super(Pipeline.new(
          to_domain_event: Transformation::ProtoEvent.new,
          transformations: [
            Transformation::ProtobufEncoder.new,
            Transformation::EventClassRemapper.new(events_class_remapping),
            Transformation::ProtobufNestedStructMetadata.new,
          ]
        ))
      end
    end
  end
end
