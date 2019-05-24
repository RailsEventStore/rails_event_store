module RubyEventStore
  module Mappers
    class NullMapper < PipelineMapper

      def initialize
        super(Pipeline.new)
      end
    end
  end
end
