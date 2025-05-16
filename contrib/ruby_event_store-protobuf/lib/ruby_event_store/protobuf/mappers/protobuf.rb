# frozen_string_literal: true

module RubyEventStore
  module Protobuf
    class Proto < RubyEventStore::Event
      def event_type
        data.class.descriptor.name
      end
    end

    module Mappers
      class Protobuf < RubyEventStore::Mappers::PipelineMapper
        def initialize(events_class_remapping: {})
          super(
            RubyEventStore::Mappers::Pipeline.new(
              Transformation::ProtobufEncoder.new,
              RubyEventStore::Mappers::Transformation::EventClassRemapper.new(events_class_remapping),
              Transformation::ProtobufNestedStructMetadata.new,
              to_domain_event: Transformation::ProtoEvent.new,
            ),
          )
        end
      end
    end
  end
end
