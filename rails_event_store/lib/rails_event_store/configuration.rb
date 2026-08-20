# frozen_string_literal: true

module RailsEventStore
  # Defaults of RailsEventStore. Version dispatch lives in the parent class,
  # here only the values which differ from RubyEventStore are set.
  #
  #   RailsEventStore.configure do |config|
  #     config.load_defaults("3.0")
  #     config.serializer = JSON
  #   end
  class Configuration < RubyEventStore::Configuration
    attr_accessor :serializer, :request_metadata

    private

    def load_upcoming_defaults
      super
      self.serializer = RubyEventStore::Serializers::YAML
      self.build_repository = -> { RubyEventStore::ActiveRecord::EventRepository.new(serializer: variant == :json ? JSON : serializer) }
      self.build_mapper = -> { preconfigured_json_mapper } if variant == :json
      self.build_subscriptions = -> {
        RubyEventStore::InstrumentedSubscriptions.new(RubyEventStore::Subscriptions.new, ActiveSupport::Notifications)
      }
      self.build_dispatcher = -> {
        RubyEventStore::InstrumentedDispatcher.new(
          RubyEventStore::ComposedDispatcher.new(
            AfterCommitDispatcher.new(scheduler: ActiveJobScheduler.new(serializer: serializer)),
            RubyEventStore::SyncScheduler.new,
          ),
          ActiveSupport::Notifications,
        )
      }
      self.request_metadata = ->(env) do
        request = ActionDispatch::Request.new(env)
        { remote_ip: request.remote_ip, request_id: request.uuid }
      end
    end

    def preconfigured_json_mapper
      RubyEventStore::Mappers::BatchMapper.new(
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
      )
    end
  end

  class << self
    def configuration(variant = nil)
      @configuration ||= Configuration.new(variant)
    end

    def configure(variant = nil)
      yield(configuration(variant))
    end
  end
end
