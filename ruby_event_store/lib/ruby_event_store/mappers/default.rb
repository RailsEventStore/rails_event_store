# frozen_string_literal: true

require 'yaml'

module RubyEventStore
  module Mappers
    class Default < PipelineMapper
      def initialize(events_class_remapping: {})
        super(Pipeline.new(
          Transformation::EventClassRemapper.new(events_class_remapping),
          Transformation::SymbolizeMetadataKeys.new,
        ))
      end
    end
  end
end
