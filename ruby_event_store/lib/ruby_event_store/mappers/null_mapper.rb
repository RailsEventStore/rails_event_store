module RubyEventStore
  module Mappers
    class NullMapper
      include PipelineMapper

      def initialize
        @pipeline = Pipeline.new
      end
    end
  end
end
