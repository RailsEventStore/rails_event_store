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

    private
    attr_reader :repository
  end
end
