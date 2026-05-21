# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class Default < PipelineMapper
      Deprecations.register(
        :events_class_remapping_option,
        "`events_class_remapping` option in `RubyEventStore::Mappers::Default` is deprecated and will be removed in the next major release.\n" \
        "Use `RubyEventStore::Mappers::Transformation::Upcast` instead.",
      )

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
