module RubyEventStore
  class Facade
    def initialize(repository, event_broker = PubSub::Broker.new)
      @repository   = repository
      @event_broker = event_broker
    end
    attr_reader :repository, :event_broker

    def publish_event(event, stream_name = GLOBAL_STREAM, expected_version = :any)
      append_to_stream(stream_name, event, expected_version)
      event_broker.notify_subscribers(event)
      :ok
    end

    def append_to_stream(stream_name, event, expected_version = :any)
      validate_expected_version(stream_name, expected_version)
      repository.create(event, stream_name)
      :ok
    end

    def delete_stream(stream_name)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      repository.delete_stream(stream_name)
      :ok
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
      unsub = event_broker.add_subscriber(subscriber, event_types)
      if block_given?
        yield
        unsub.()
        DO_NOTHING
      end
      unsub
    end

    def subscribe_to_all_events(subscriber)
      unsub = event_broker.add_global_subscriber(subscriber)
      if block_given?
        yield
        unsub.()
        DO_NOTHING
      end
      unsub
    end

    private
    DO_NOTHING = -> {}

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

    def validate_expected_version(stream_name, expected_version)
      raise InvalidExpectedVersion if expected_version.nil?
      case expected_version
      when :any
        return
      when :none
        return if last_stream_event_id(stream_name).nil?
      else
        return if last_stream_event_id(stream_name).equal?(expected_version)
      end
      raise WrongExpectedEventVersion
    end

    def last_stream_event_id(stream_name)
      last = repository.last_stream_event(stream_name)
      last.event_id if last
    end
  end
end
