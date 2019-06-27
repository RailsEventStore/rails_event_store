# frozen_string_literal: true

require 'yaml'

module RubyEventStore
  module Mappers
    class Default < PipelineMapper
      def initialize(serializer: YAML, events_class_remapping: {})
        super(Pipeline.new(
          transformations: [
            Transformation::EventClassRemapper.new(events_class_remapping),
            Transformation::SymbolizeMetadataKeys.new,
            Transformation::Serialization.new(serializer: serializer),
          ]
        ))
      end
    end
  end
end
