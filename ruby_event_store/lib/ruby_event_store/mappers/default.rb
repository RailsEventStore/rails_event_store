# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class Default < PipelineMapper
      def initialize(events_class_remapping: {})
        if events_class_remapping.any?
          Deprecations.warn(:events_class_remapping_option)
          super(
            Pipeline.new(
              Transformation::EventClassRemapper.new(events_class_remapping),
              Transformation::SymbolizeMetadataKeys.new,
            ),
          )
        else
          super(Pipeline.new(Transformation::SymbolizeMetadataKeys.new))
        end
      end
    end
  end
end
