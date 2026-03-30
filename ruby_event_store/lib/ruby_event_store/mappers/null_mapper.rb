# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class NullMapper < PipelineMapper
      def initialize
        warn <<~EOW
          DEPRECATION WARNING: `RubyEventStore::Mappers::NullMapper` is deprecated and will be removed in the next major release.
          Use `RubyEventStore::Mappers::Default.new` instead.
        EOW
        super(Pipeline.new)
      end
    end
  end
end
