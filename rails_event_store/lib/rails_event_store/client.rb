# frozen_string_literal: true

module RailsEventStore
  class Client < RubyEventStore::Client
    attr_reader :request_metadata

    def initialize(mapper: RubyEventStore::Mappers::Default.new,
                   repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: mapper.serializer),
                   subscriptions: RubyEventStore::Subscriptions.new,
                   dispatcher: RubyEventStore::ComposedDispatcher.new(
                     RailsEventStore::AfterCommitAsyncDispatcher.new(scheduler: ActiveJobScheduler.new(serializer: mapper.serializer)),
                     RubyEventStore::Dispatcher.new),
                   request_metadata: default_request_metadata)
      super(repository: RubyEventStore::InstrumentedRepository.new(repository, ActiveSupport::Notifications),
            mapper: RubyEventStore::Mappers::InstrumentedMapper.new(mapper, ActiveSupport::Notifications),
            subscriptions: subscriptions,
            dispatcher: RubyEventStore::InstrumentedDispatcher.new(dispatcher, ActiveSupport::Notifications)
            )
      @request_metadata = request_metadata
    end

    def with_request_metadata(env, &block)
      with_metadata(request_metadata.call(env)) do
        block.call
      end
    end

    private
    def default_request_metadata
      ->(env) do
        request = ActionDispatch::Request.new(env)
        {
          remote_ip:  request.remote_ip,
          request_id: request.uuid
        }
      end
    end
  end
end
