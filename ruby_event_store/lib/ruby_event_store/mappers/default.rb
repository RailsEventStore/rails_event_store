require 'yaml'

module RubyEventStore
  module Mappers
    class Default
      def initialize(serializer: YAML, events_class_remapping: {})
        @pipeline = Pipeline.new([
          DomainEventMapper.new,
          EventClassRemapper.new(events_class_remapping),
          SymbolizeKeys.new(symbolize_data: false),
          SerializedRecordMapper.new(serializer: serializer)
        ])
      end

      def event_to_serialized_record(domain_event)
        pipeline.dump(domain_event)
      end

      def serialized_record_to_event(record)
        pipeline.load(record)
      end

      private
      attr_reader :pipeline
    end
  end
end
