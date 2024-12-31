# frozen_string_literal: true

module RailsEventStore
  class JSONClient < Client
    def initialize(
      mapper: RubyEventStore::Mappers::PipelineMapper.new(
        RubyEventStore::Mappers::Pipeline.new(
          RubyEventStore::Mappers::Transformation::PreserveTypes
            .new
            .register(Symbol, serializer: ->(v) { v.to_s }, deserializer: ->(v) { v.to_sym })
            .register(
              Time,
              serializer: ->(v) { v.iso8601(RubyEventStore::TIMESTAMP_PRECISION) },
              deserializer: ->(v) { Time.iso8601(v) },
            )
            .register(
              ActiveSupport::TimeWithZone,
              serializer: ->(v) { v.iso8601(RubyEventStore::TIMESTAMP_PRECISION) },
              deserializer: ->(v) { Time.iso8601(v).in_time_zone },
              stored_type: ->(*) { "ActiveSupport::TimeWithZone" },
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
            )
            .register(
              BigDecimal,
              serializer: ->(v) { v.to_s },
              deserializer: ->(v) { BigDecimal(v) },
            )
            .register(
              OpenStruct,
              serializer: ->(v) { v.to_h },
              deserializer: ->(v) { OpenStruct.new(v) },
            ),
          RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new,
        ),
      ),
      repository: RubyEventStore::ActiveRecord::EventRepository.new(
        serializer: RubyEventStore::NULL,
      ),
      subscriptions: RubyEventStore::Subscriptions.new,
      dispatcher: RubyEventStore::ComposedDispatcher.new(
        RailsEventStore::AfterCommitAsyncDispatcher.new(
          scheduler: ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML),
        ),
        RubyEventStore::Dispatcher.new,
      ),
      clock: default_clock,
      correlation_id_generator: default_correlation_id_generator,
      request_metadata: default_request_metadata
    )
      super(
        mapper:
          RubyEventStore::Mappers::InstrumentedMapper.new(mapper, ActiveSupport::Notifications),
        repository:
          RubyEventStore::InstrumentedRepository.new(repository, ActiveSupport::Notifications),
        subscriptions:
          RubyEventStore::InstrumentedSubscriptions.new(
            subscriptions,
            ActiveSupport::Notifications,
          ),
        clock: clock,
        correlation_id_generator: correlation_id_generator,
        dispatcher:
          RubyEventStore::InstrumentedDispatcher.new(dispatcher, ActiveSupport::Notifications),
      )
      @request_metadata = request_metadata
    end
  end
end
