# frozen_string_literal: true

module RailsEventStore
  class Client < RubyEventStore::Client
    attr_reader :request_metadata

    def initialize(
      mapper: RubyEventStore::Mappers::Default.new,
      repository: RubyEventStore::ActiveRecord::EventRepository.new(serializer: RubyEventStore::Serializers::YAML),
      subscriptions: nil,
      dispatcher: nil,
      message_broker: nil,
      clock: default_clock,
      correlation_id_generator: default_correlation_id_generator,
      request_metadata: default_request_metadata
    )
      super(
        repository: RubyEventStore::InstrumentedRepository.new(repository, ActiveSupport::Notifications),
        mapper: RubyEventStore::Mappers::InstrumentedMapper.new(mapper, ActiveSupport::Notifications),
        subscriptions: nil,
        clock: clock,
        correlation_id_generator: correlation_id_generator,
        dispatcher: nil,
        message_broker: message_broker || RubyEventStore::Broker.new(
          subscriptions: RubyEventStore::InstrumentedSubscriptions.new(
            subscriptions || RubyEventStore::Subscriptions.new,
            ActiveSupport::Notifications
          ),
          dispatcher: RubyEventStore::InstrumentedDispatcher.new(
            dispatcher || RubyEventStore::ComposedDispatcher.new(
              RailsEventStore::AfterCommitAsyncDispatcher.new(
                scheduler: ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML)
              ),
              RubyEventStore::Dispatcher.new
            ),
            ActiveSupport::Notifications
          ),
        )
      )
      @request_metadata = request_metadata
    end

    def with_request_metadata(env, &block)
      with_metadata(request_metadata.call(env)) { block.call }
    end

    private

    def default_request_metadata
      ->(env) do
        request = ActionDispatch::Request.new(env)
        { remote_ip: request.remote_ip, request_id: request.uuid }
      end
    end
  end
end
