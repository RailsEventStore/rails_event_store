module RubyEventStore
  class Facade
    PAGE_SIZE = 100

    def initialize(repository)
      @repository = repository
    end
    attr_reader :repository

    def publish_event(event_data, stream_name = GLOBAL_STREAM, expected_version = nil)
      event = append_to_stream(stream_name, event_data, expected_version)
      event_broker.notify_subscribers(event)
    end

    def append_to_stream(stream_name, event_data, expected_version = nil)
      raise WrongExpectedEventVersion if version_incorrect?(stream_name, expected_version)
      repository.create(event_data, stream_name)
    end

    def delete_stream(stream_name)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      repository.delete_stream(stream_name)
    end

    def read_events_forward(stream_name, start = nil, count = PAGE_SIZE)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      ensure_event_exists(start) if start
      repository.read_events_forward(stream_name, start, count)
    end

    def read_events_backward(stream_name, start = nil, count = PAGE_SIZE)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      ensure_event_exists(start) if start
      repository.read_events_backward(stream_name, start, count)
    end

    def read_stream_events_forward(stream_name)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      repository.read_stream_events_forward(stream_name)
    end

    def read_stream_events_backward(stream_name)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      repository.read_stream_events_backward(stream_name)
    end

    def read_all_streams_forward(start = nil, count = PAGE_SIZE)
      ensure_event_exists(start) if start
      repository.read_all_streams_forward(start, count)
    end

    def read_all_streams_backward(start = nil, count = PAGE_SIZE)
      ensure_event_exists(start) if start
      repository.read_all_streams_backward(start, count)
    end

    def subscribe(subscriber, event_types)
      event_broker.add_subscriber(subscriber, event_types)
    end

    def subscribe_to_all_events(subscriber)
      event_broker.add_global_subscriber(subscriber)
    end

    private

    def event_broker
      @event_broker ||= PubSub::Broker.new
    end

    def version_incorrect?(stream_name, expected_version)
      unless expected_version.nil?
        find_last_event_version(stream_name) != expected_version
      end
    end

    def ensure_event_exists(event_id)
      raise EventNotFound unless repository.has_event?(event_id.to_s)
    end

    def find_last_event_version(stream_name)
      repository.last_stream_event(stream_name).event_id
    end
  end
end
