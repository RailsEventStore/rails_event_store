module RailsEventStore
  class Client

    def append_to_stream(stream_name, event_data, expected_version = nil)
      Actions::AppendEventToStream.new(event_repository).call(stream_name, event_data, expected_version)
    end

    def delete_stream(stream_name)
      Actions::DeleteStreamEvents.new(event_repository).call(stream_name)
    end

    def read_events_forward(stream_name, start, count)
      Actions::ReadEventsBatch.new(event_repository).call(stream_name, start, count, :forward)
    end

    def read_events_backward(stream_name, start, count)
      Actions::ReadEventsBatch.new(event_repository).call(stream_name, start, count, :backward)
    end

    def read_all_events_forward(stream_name)
      Actions::ReadAllEvents.new(event_repository).call(stream_name, :forward)
    end

    def read_all_events_backward(stream_name)
      Actions::ReadAllEvents.new(event_repository).call(stream_name, :backward)
    end

    def read_all_streams
      Actions::ReadAllStreams.new(event_repository).call
    end

    private

    def event_repository
      @repository ||= Repositories::EventRepository.new
    end

  end
end
