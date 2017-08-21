module RailsEventStore
  class Client < RubyEventStore::Client
    def initialize(repository: RailsEventStore.event_repository,
                   event_broker: EventBroker.new,
                   page_size: PAGE_SIZE)
      capture_metadata = ->{ Thread.current[:rails_event_store] }
      super(repository: repository,
            event_broker: event_broker,
            page_size: page_size,
            metadata_proc: capture_metadata)
    end

    def publish_event(event, **kwargs)
      ActiveSupport::Notifications.instrument("publish_event.rails_event_store", event: event) do
        super
      end
    end
  end
end
