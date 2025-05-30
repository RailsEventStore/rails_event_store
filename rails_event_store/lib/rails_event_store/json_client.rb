# frozen_string_literal: true

require "json"

module RailsEventStore
  class JSONClient < Client
    def initialize(
      mapper: RubyEventStore::Mappers::BatchMapper.new(
        RubyEventStore::Mappers::PipelineMapper.new(
          RubyEventStore::Mappers::Pipeline.new(
            {
              Symbol => {
                serializer: ->(v) { v.to_s },
                deserializer: ->(v) { v.to_sym },
              },
              Time => {
                serializer: ->(v) { v.iso8601(RubyEventStore::TIMESTAMP_PRECISION) },
                deserializer: ->(v) { Time.iso8601(v) },
              },
              ActiveSupport::TimeWithZone => {
                serializer: ->(v) { v.iso8601(RubyEventStore::TIMESTAMP_PRECISION) },
                deserializer: ->(v) { Time.iso8601(v).in_time_zone },
                stored_type: ->(*) { "ActiveSupport::TimeWithZone" },
              },
              Date => {
                serializer: ->(v) { v.iso8601 },
                deserializer: ->(v) { Date.iso8601(v) },
              },
              DateTime => {
                serializer: ->(v) { v.iso8601 },
                deserializer: ->(v) { DateTime.iso8601(v) },
              },
              BigDecimal => {
                serializer: ->(v) { v.to_s },
                deserializer: ->(v) { BigDecimal(v) },
              },
            }.merge(
              if defined?(OpenStruct)
                { OpenStruct => { serializer: ->(v) { v.to_h }, deserializer: ->(v) { OpenStruct.new(v) } } }
              else
                {}
              end,
            )
              .reduce(RubyEventStore::Mappers::Transformation::PreserveTypes.new) do |preserve_types, (klass, options)|
                preserve_types.register(klass, **options)
              end,
            RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new,
          ),
        ),
      ),
      repository: RubyEventStore::ActiveRecord::EventRepository.new(serializer: JSON),
      subscriptions: nil,
      dispatcher: nil,
      message_broker: nil,
      clock: default_clock,
      correlation_id_generator: default_correlation_id_generator,
      request_metadata: default_request_metadata
    )
      super
    end
  end
end
