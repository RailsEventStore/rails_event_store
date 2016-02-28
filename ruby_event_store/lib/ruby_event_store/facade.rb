module RubyEventStore
  class Facade

    def initialize(repository)
      @repository = repository
    end
    attr_reader :repository

    def publish_event(event_data, stream_name = GLOBAL_STREAM, expected_version = nil)
      raise WrongExpectedEventVersion if version_incorrect?(stream_name, expected_version)
      event = repository.create(event_data.to_h.merge!(stream: stream_name))
      event_broker.notify_subscribers(event)
    end

    def delete_stream(stream_name)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      repository.delete({stream: stream_name})
    end

    def read_events(stream_name, start, count)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      event = find_event(start)
      repository.load_events_batch(stream_name, event.id, count)
    end

    def read_all_events(stream_name)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      repository.load_all_events_forward(stream_name)
    end

    def read_all_streams
      repository.get_all_events
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

    def find_last_event_version(stream_name)
      repository.last_stream_event(stream_name).event_id
    end

    def find_event(start)
      event = repository.find({event_id: start})
      raise EventNotFound if event.nil?
      event
    end
  end
end
