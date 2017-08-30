module RubyEventStore
  class Client
    def initialize(repository:,
                   event_broker:  PubSub::Broker.new,
                   page_size: PAGE_SIZE,
                   metadata_proc: nil,
                   clock: ->{ Time.now.utc })
      @repository     = repository
      @event_broker   = event_broker
      @page_size      = page_size
      @metadata_proc  = metadata_proc
      @clock          = clock
    end

    def publish_events(events, stream_name: GLOBAL_STREAM, expected_version: :any)
      append_to_stream(events, stream_name: stream_name, expected_version: expected_version)
      events.each do |ev|
        event_broker.notify_subscribers(ev)
      end
      :ok
    end

    def publish_event(event, stream_name: GLOBAL_STREAM, expected_version: :any)
      publish_events([event], stream_name: stream_name, expected_version: expected_version)
    end

    def append_to_stream(events, stream_name: GLOBAL_STREAM, expected_version: :any)
      events = *events
      events.each{|event| enrich_event_metadata(event) }
      repository.append_to_stream(events, stream_name, expected_version)
      :ok
    end

    def delete_stream(stream_name)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      repository.delete_stream(stream_name)
      :ok
    end

    def read_events_forward(stream_name, start: :head, count: page_size)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      page = Page.new(repository, start, count)
      repository.read_events_forward(stream_name, page.start, page.count)
    end

    def read_events_backward(stream_name, start: :head, count: page_size)
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

    def read_all_streams_forward(start: :head, count: page_size)
      page = Page.new(repository, start, count)
      repository.read_all_streams_forward(page.start, page.count)
    end

    def read_all_streams_backward(start: :head, count: page_size)
      page = Page.new(repository, start, count)
      repository.read_all_streams_backward(page.start, page.count)
    end

    def subscribe(subscriber, event_types, &proc)
      event_broker.add_subscriber(subscriber, event_types).tap do |unsub|
        handle_subscribe(unsub, &proc)
      end
    end

    def subscribe_to_all_events(subscriber, &proc)
      event_broker.add_global_subscriber(subscriber).tap do |unsub|
        handle_subscribe(unsub, &proc)
      end
    end

    private
    attr_reader :repository, :page_size, :event_broker, :metadata_proc, :clock

    def enrich_event_metadata(event)
      metadata = event.metadata
      metadata[:timestamp] ||= clock.()
      metadata.merge!(metadata_proc.call || {}) if metadata_proc

      # event.class.new(event_id: event.event_id, metadata: metadata, data: event.data)
    end

    def handle_subscribe(unsub)
      if block_given?
        yield
        unsub.()
      end
    end

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

  end
end
