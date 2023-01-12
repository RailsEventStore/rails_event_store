# frozen_string_literal: true

module RailsEventStore
  class JSONClient < Client
    def initialize(repository: RubyEventStore::ActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL))
      super(
        mapper:
          RubyEventStore::Mappers::PipelineMapper.new(
            RubyEventStore::Mappers::Pipeline.new(
              RubyEventStore::Mappers::Transformation::PreserveTypes
                .new
                .register(Symbol, serializer: ->(v) { v.to_s }, deserializer: ->(v) { v.to_sym })
                .register(
                  Time,
                  serializer: ->(v) { v.iso8601(RubyEventStore::TIMESTAMP_PRECISION) },
                  deserializer: ->(v) { Time.iso8601(v) }
                )
                .register(
                  ActiveSupport::TimeWithZone,
                  serializer: ->(v) { v.iso8601(RubyEventStore::TIMESTAMP_PRECISION) },
                  deserializer: ->(v) { Time.iso8601(v).in_time_zone },
                  stored_type: ->(*) { "ActiveSupport::TimeWithZone" }
                )
                .register(Date, serializer: ->(v) { v.iso8601 }, deserializer: ->(v) { Date.iso8601(v) })
                .register(DateTime, serializer: ->(v) { v.iso8601 }, deserializer: ->(v) { DateTime.iso8601(v) }),
              RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new
            )
          ),
        repository: repository
      )
    end
  end
end
