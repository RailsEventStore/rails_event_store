module RailsEventStore
  class Client

    def initialize(repository: EventRepository.new,
                   event_broker: EventBroker.new,
                   page_size: PAGE_SIZE)
      @repository = repository
      @page_size = page_size
      @event_broker = event_broker
    end

    def publish_event(event, stream_name: GLOBAL_STREAM, expected_version: :any)
      event_store.publish_event(event, stream_name: stream_name, expected_version: expected_version)
    end

    def append_to_stream(event, stream_name: GLOBAL_STREAM, expected_version: :any)
      event_store.append_to_stream(stream_name, event, expected_version: expected_version)
    end

    def delete_stream(stream_name)
      event_store.delete_stream(stream_name)
    end

    def read_events_forward(stream_name, start: :head, count: page_size)
      event_store.read_events_forward(stream_name, start, count)
    end

    def read_events_backward(stream_name, start: :head, count: page_size)
      event_store.read_events_backward(stream_name, start, count)
    end

    def read_stream_events_forward(stream_name)
      event_store.read_stream_events_forward(stream_name)
    end

    def read_stream_events_backward(stream_name)
      event_store.read_stream_events_backward(stream_name)
    end

    def read_all_streams_forward(start: :head, count: page_size)
      event_store.read_all_streams_forward(start, count)
    end

    def read_all_streams_backward(start: :head, count: page_size)
      event_store.read_all_streams_backward(start, count)
    end

    def subscribe(subscriber, event_types, &proc)
      event_store.subscribe(subscriber, event_types, &proc)
    end

    def subscribe_to_all_events(subscriber, &proc)
      event_store.subscribe_to_all_events(subscriber, &proc)
    end

    private
    attr_reader :repository, :page_size, :event_broker

    def event_store
      capture_metadata = ->{ Thread.current[:rails_event_store] }
      @event_store ||= RubyEventStore::Client.new(repository,
                                                  event_broker: event_broker,
                                                  metadata_proc: capture_metadata)
    end
  end
end
