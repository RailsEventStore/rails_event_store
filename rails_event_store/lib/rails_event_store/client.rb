# frozen_string_literal: true

module RailsEventStore
  class Client < RubyEventStore::Client
    attr_reader :request_metadata

    def initialize(
      mapper: nil,
      repository: nil,
      subscriptions: nil,
      dispatcher: nil,
      message_broker: nil,
      clock: nil,
      correlation_id_generator: nil,
      request_metadata: nil,
      configuration: RailsEventStore.configuration
    )
      mapper ||= configuration.build_mapper.call
      super(
        repository:
          RubyEventStore::InstrumentedRepository.new(
            repository || configuration.build_repository.call,
            ActiveSupport::Notifications,
          ),
        mapper:
          (
            if batch_mapper?(mapper)
              RubyEventStore::Mappers::InstrumentedBatchMapper.new(mapper, ActiveSupport::Notifications)
            else
              RubyEventStore::Mappers::InstrumentedMapper.new(mapper, ActiveSupport::Notifications)
            end
          ),
        subscriptions: nil,
        clock: clock,
        correlation_id_generator: correlation_id_generator,
        dispatcher: nil,
        message_broker:
          RubyEventStore::InstrumentedBroker.new(
            build_instrumented_broker(configuration, message_broker, subscriptions, dispatcher),
            ActiveSupport::Notifications,
          ),
        configuration: configuration,
      )
      @request_metadata = request_metadata || configuration.request_metadata

      if (subscriptions || dispatcher)
        msg = <<~EOW
          Passing subscriptions and dispatcher to #{self.class} has been deprecated.

          Pass it using message_broker argument. For example:

          event_store = #{self.class}.new(
            message_broker: RubyEventStore::Broker.new(
              subscriptions: RubyEventStore::Subscriptions.new,
              dispatcher: RubyEventStore::ComposedDispatcher.new(
                RailsEventStore::AfterCommitDispatcher.new(
                  scheduler: RailsEventStore::ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML)
                ),
                RubyEventStore::SyncScheduler.new
              )
            )
          )
        EOW
        msg += <<~EOW if message_broker

          Because message_broker has been provided,
          arguments passed by subscriptions or dispatcher will be ignored.
        EOW
        RubyEventStore::Deprecations.warn(:rails_client_subscriptions_dispatcher, message: msg)
      end
    end

    def with_request_metadata(env, &block)
      with_metadata(request_metadata.call(env)) { block.call }
    end

    private

    def build_instrumented_broker(configuration, message_broker, subscriptions, dispatcher)
      return message_broker if message_broker
      return configuration.build_message_broker.call unless subscriptions || dispatcher

      RubyEventStore::Broker.new(
        subscriptions:
          if subscriptions
            RubyEventStore::InstrumentedSubscriptions.new(subscriptions, ActiveSupport::Notifications)
          else
            configuration.build_subscriptions.call
          end,
        dispatcher:
          if dispatcher
            RubyEventStore::InstrumentedDispatcher.new(dispatcher, ActiveSupport::Notifications)
          else
            configuration.build_dispatcher.call
          end,
      )
    end
  end
end
