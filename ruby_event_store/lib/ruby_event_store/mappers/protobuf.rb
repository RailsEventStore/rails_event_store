# frozen_string_literal: true

module RubyEventStore
  class Proto < RubyEventStore::Event
    def event_type
      data.class.descriptor.name
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
