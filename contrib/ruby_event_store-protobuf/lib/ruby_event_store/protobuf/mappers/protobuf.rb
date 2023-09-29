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
        def initialize
          super(
            RubyEventStore::Mappers::Pipeline.new(
              Transformation::ProtobufEncoder.new,
              Transformation::ProtobufNestedStructMetadata.new,
              to_domain_event: Transformation::ProtoEvent.new
            )
          )
        end
      end
    end
  end
end
