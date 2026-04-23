# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class PipelineMapper
      def initialize(pipeline)
        @pipeline = pipeline
      end

      def event_to_record(event)
        pipeline.dump(event)
      end

      def record_to_event(record)
        pipeline.load(record)
      end

      def cleaner_inspect(indent: 0)
        transformations_list = pipeline.transformations.map { |t| "#{' ' * (indent + 4)}- #{t.inspect}" }.join("\n")
        <<~EOS.chomp
          #{' ' * indent}#<#{self.class}:0x#{__id__.to_s(16)}>
          #{' ' * indent}  - transformations:
          #{transformations_list}
        EOS
      end

      private

      attr_reader :pipeline
    end
  end
end
