module RailsEventStore
  class InstrumentedRepository
    def initialize(repository)
      @repository = repository
    end

    def append_to_stream(events, stream, expected_version)
      ActiveSupport::Notifications.instrument("append_to_stream.repository.rails_event_store", events: events, stream: stream) do
        repository.append_to_stream(events, stream, expected_version)
      end
    end

    def link_to_stream(event_ids, stream, expected_version)
      ActiveSupport::Notifications.instrument("link_to_stream.repository.rails_event_store", event_ids: event_ids, stream: stream) do
        repository.link_to_stream(event_ids, stream, expected_version)
      end
    end

    def delete_stream(stream)
      ActiveSupport::Notifications.instrument("delete_stream.repository.rails_event_store", stream: stream) do
        repository.delete_stream(stream)
      end
    end

    def has_event?(event_id)
      repository.has_event?(event_id)
    end

    def last_stream_event(stream)
      repository.last_stream_event(stream)
    end

    def read_event(event_id)
      ActiveSupport::Notifications.instrument("read_event.repository.rails_event_store", event_id: event_id) do
        repository.read_event(event_id)
      end
    end

    def read(specification)
      ActiveSupport::Notifications.instrument("read.repository.rails_event_store", specification: specification) do
        repository.read(specification)
      end
    end

    private
    attr_reader :repository
  end
end
