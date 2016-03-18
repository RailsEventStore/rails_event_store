module RubyEventStore
  class Facade
    def initialize(repository, event_broker = PubSub::Broker.new)
      @repository   = repository
      @event_broker = event_broker
    end
    attr_reader :repository, :event_broker

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

    def read_events_forward(stream_name, start, count)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      page = Page.new(repository, start, count)
      repository.read_events_forward(stream_name, page.start, page.count)
    end

    def read_events_backward(stream_name, start, count)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      page = Page.new(repository, start, count)
      repository.read_events_backward(stream_name, page.start, page.count)
    end

    def read_stream_events_forward(stream_name)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      repository.read_stream_events_forward(stream_name)
    end

    def read_stream_events_backward(stream_name)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      repository.read_stream_events_backward(stream_name)
    end

    def read_all_streams_forward(start, count)
      page = Page.new(repository, start, count)
      repository.read_all_streams_forward(page.start, page.count)
    end

    def read_all_streams_backward(start, count)
      page = Page.new(repository, start, count)
      repository.read_all_streams_backward(page.start, page.count)
    end

    def subscribe(subscriber, event_types)
      event_broker.add_subscriber(subscriber, event_types)
    end

    def subscribe_to_all_events(subscriber)
      event_broker.add_global_subscriber(subscriber)
    end

    private

    class Page
      def initialize(repository, start, count)
        if start.instance_of?(Symbol)
          raise InvalidPageStart unless [:head].include?(start)
        else
          start = start.to_s
          raise InvalidPageStart if start.empty?
          raise EventNotFound unless repository.has_event?(start)
        end
        raise InvalidPageSize unless count > 0
        @start = start
        @count = count
      end
      attr_reader :start, :count
    end

    def version_incorrect?(stream_name, expected_version)
      unless expected_version.nil?
        find_last_event_version(stream_name) != expected_version
      end
    end

    def find_last_event_version(stream_name)
      repository.last_stream_event(stream_name).event_id
    end
  end
end
