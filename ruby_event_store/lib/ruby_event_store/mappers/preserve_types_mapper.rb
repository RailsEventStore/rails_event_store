# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class PreserveTypesMapper < RubyEventStore::Mappers::PipelineMapper
      def initialize
        super(Pipeline.new(
          Transformation::PreserveTypes
            .new
            .register(
              Symbol,
              serializer: ->(v) { v.to_s },
              deserializer: ->(v) { v.to_sym },
            )
            .register(
              Time,
              serializer: ->(v) { v.iso8601(TIMESTAMP_PRECISION) },
              deserializer: ->(v) { Time.iso8601(v) },
            )
            .register(
              ActiveSupport::TimeWithZone,
              serializer: ->(v) { v.iso8601(TIMESTAMP_PRECISION) },
              deserializer: ->(v) { Time.iso8601(v).in_time_zone },
              stored_type: -> (*) { "ActiveSupport::TimeWithZone" }
            )
            .register(
              Date,
              serializer: ->(v) { v.iso8601 },
              deserializer: ->(v) { Date.iso8601(v) },
            )
            .register(
              DateTime,
              serializer: ->(v) { v.iso8601 },
              deserializer: ->(v) { DateTime.iso8601(v) },
            ),
          Transformation::SymbolizeMetadataKeys.new,
        ))
      end
    end
  end
end