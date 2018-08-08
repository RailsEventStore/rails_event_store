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

    private
    attr_reader :repository
  end
end
