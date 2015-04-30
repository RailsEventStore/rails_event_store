module RailsEventStore
  class Client

    def initialize(repository = Repositories::EventRepository.new)
      @repository = repository
    end
    attr_reader :repository

    def publish_event(event_data, stream_name = GLOBAL_STREAM, expected_version = nil)
      event = Actions::AppendEventToStream.new(@repository).call(stream_name, event_data, expected_version)
      event_broker.notify_subscribers(event)
    end

    def delete_stream(stream_name)
      Actions::DeleteStreamEvents.new(@repository).call(stream_name)
    end

    def read_events(stream_name, start, count)
      Actions::ReadEventsBatch.new(@repository).call(stream_name, start, count)
    end

    def read_all_events(stream_name)
      Actions::ReadAllEvents.new(@repository).call(stream_name)
    end

    def read_all_streams
      Actions::ReadAllStreams.new(@repository).call
    end

    def subscribe(subscriber, event_types = [ ALL_EVENTS ])
      event_broker.add_subscriber(subscriber, event_types)
    end

    private

    def event_broker
      @event_broker ||= PubSub::Broker.new
    end
  end
end
