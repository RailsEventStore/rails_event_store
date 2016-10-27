module RailsEventStore
  class Client < RubyEventStore::Client
    def initialize(repository: Repository.adapter,
                   event_broker: EventBroker.new,
                   page_size: PAGE_SIZE)
      capture_metadata = ->{ Thread.current[:rails_event_store] }
      super(repository: repository,
            event_broker: event_broker,
            page_size: page_size,
            metadata_proc: capture_metadata)
    end
  end
end
