require 'yaml'

module RubyEventStore
  module Mappers
    class Default
      include PipelineMapper

      def initialize(serializer: YAML, events_class_remapping: {})
        @pipeline = Pipeline.new(
          to_serialized_record: SerializedRecordMapper.new(serializer: serializer),
          transformations: [
            EventClassRemapper.new(events_class_remapping),
            SymbolizeMetadataKeys.new,
          ]
        )
      end
    end
  end
end
