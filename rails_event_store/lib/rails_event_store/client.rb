module RailsEventStore
  class Client

    def initialize(repository=Repositories::EventRepository.new)
      @repository = repository
      @observers = []
    end

    def append_to_stream(stream_name, event_data, expected_version = nil)
      event = Actions::AppendEventToStream.new(@repository).call(stream_name, event_data, expected_version)
      @observers.each {|observer| observer.handle_event(event)}
    end

    def delete_stream(stream_name)
      Actions::DeleteStreamEvents.new(@repository).call(stream_name)
    end

    def read_events_forward(stream_name, start, count)
      Actions::ReadEventsBatch.new(@repository).call(stream_name, start, count, :forward)
    end

    def read_events_backward(stream_name, start, count)
      Actions::ReadEventsBatch.new(@repository).call(stream_name, start, count, :backward)
    end

    def read_all_events_forward(stream_name)
      Actions::ReadAllEvents.new(@repository).call(stream_name, :forward)
    end

    def read_all_events_backward(stream_name)
      Actions::ReadAllEvents.new(@repository).call(stream_name, :backward)
    end

    def read_all_streams
      Actions::ReadAllStreams.new(@repository).call
    end

    def subscribe_to_all_events(observer)
      @observers << observer
    end

  end
end
