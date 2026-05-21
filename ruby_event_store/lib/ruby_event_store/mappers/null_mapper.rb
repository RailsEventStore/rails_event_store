# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class NullMapper < PipelineMapper
      Deprecations.register(
        :null_mapper,
        "`RubyEventStore::Mappers::NullMapper` is deprecated and will be removed in the next major release.\n" \
        "Use `RubyEventStore::Mappers::Default.new` instead.",
      )

      def initialize
        Deprecations.warn(:null_mapper)
        super(Pipeline.new)
      end
    end
  end
end
