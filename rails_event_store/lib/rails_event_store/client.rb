module RailsEventStore
  class Client < RubyEventStore::Client
    def initialize(repository: RailsEventStoreActiveRecord::EventRepository.new,
                   mapper: RubyEventStore::Mappers::Default.new,
                   event_broker: EventBroker.new(dispatcher: ActiveJobDispatcher.new),
                   page_size: PAGE_SIZE)
      super(repository: repository,
            mapper: mapper,
            event_broker: event_broker,
            page_size: page_size)
    end
  end
end
