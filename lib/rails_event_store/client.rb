module RailsEventStore
  class Client

    def append_to_stream(stream_name, event_data, expected_version = nil)
      Actions::AppendEventToStream.new(event_repository).call(stream_name, event_data, expected_version)
    end

    def delete_stream(stream_name)
      #TODO
    end

    def read_events_forward
      #TODO
    end

    def read_events_backward
      #TODO
    end

    def read_all_events_forward
      #TODO
    end

    def read_all_events_backward
      #TODO
    end

    private

    def event_repository
      @repository ||= Repositories::EventRepository.new
    end

  end
end