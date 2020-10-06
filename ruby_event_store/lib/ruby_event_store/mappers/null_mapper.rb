# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class NullMapper < PipelineMapper

      def initialize
        super(Pipeline.new)
      end

      def serializer
        NULL
      end
    end
  end
end
