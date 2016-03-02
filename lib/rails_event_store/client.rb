module RailsEventStore
  class Client

    def initialize(repository = Repositories::EventRepository.new, page_size = PAGE_SIZE)
      @repository = repository
      @page_size = page_size
    end
    attr_reader :repository, :page_size

    def publish_event(event_data, stream_name = GLOBAL_STREAM, expected_version = nil)
      event_store.publish_event(event_data, stream_name, expected_version)
    end

    def delete_stream(stream_name)
      event_store.delete_stream(stream_name)
    end

    def read_events(stream_name, start = :head, count = page_size)
      event_store.read_events_forward(stream_name, start, count)
    end

    def read_all_events(stream_name)
      event_store.read_stream_events_forward(stream_name)
    end

    def read_all_streams(start = :head, count = page_size)
      event_store.read_all_streams_forward(start, count)
    end

    def subscribe(subscriber, event_types)
      event_store.subscribe(subscriber, event_types)
    end

    def subscribe_to_all_events(subscriber)
      event_store.subscribe_to_all_events(subscriber)
    end

    private

    def event_store
      @event_store ||= RubyEventStore::Facade.new(repository)
    end
  end
end
