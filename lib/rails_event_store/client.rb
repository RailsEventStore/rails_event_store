module RailsEventStore
  class Client

    def initialize(repository: RailsEventStoreActiveRecord::EventRepository.new,
                   event_broker: EventBroker.new,
                   lock_obtainer: nil,
                   page_size: PAGE_SIZE)
      @repository = repository
      @page_size = page_size
      @event_broker = event_broker
      @lock_obtainer = lock_obtainer
    end

    def publish_event(event, stream_name = GLOBAL_STREAM, expected_version = :any)
      event_store.publish_event(event, stream_name, expected_version)
    end

    def append_to_stream(event, stream_name = GLOBAL_STREAM, expected_version = :any)
      event_store.append_to_stream(stream_name, event, expected_version)
    end

    def delete_stream(stream_name)
      event_store.delete_stream(stream_name)
    end

    def read_events_forward(stream_name, start = :head, count = page_size)
      event_store.read_events_forward(stream_name, start, count)
    end
    alias :read_events :read_events_forward

    def read_events_backward(stream_name, start = :head, count = page_size)
      event_store.read_events_backward(stream_name, start, count)
    end

    def read_stream_events_forward(stream_name)
      event_store.read_stream_events_forward(stream_name)
    end
    alias :read_all_events :read_stream_events_forward

    def read_stream_events_backward(stream_name)
      event_store.read_stream_events_backward(stream_name)
    end

    def read_all_streams_forward(start = :head, count = page_size)
      event_store.read_all_streams_forward(start, count)
    end
    alias :read_all_streams :read_all_streams_forward

    def read_all_streams_backward(start = :head, count = page_size)
      event_store.read_all_streams_backward(start, count)
    end

    def subscribe(subscriber, event_types)
      event_store.subscribe(subscriber, event_types)
    end

    def subscribe_to_all_events(subscriber)
      event_store.subscribe_to_all_events(subscriber)
    end

    private
    attr_reader :repository, :page_size, :event_broker, :lock_obtainer

    def event_store
      @event_store ||= RubyEventStore::Facade.new(repository, event_broker, lock_obtainer)
    end
  end
end
