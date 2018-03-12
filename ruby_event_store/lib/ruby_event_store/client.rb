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
        @event_broker.notify_subscribers(ev)
      end
      :ok
    end

    def publish_event(event, stream_name: GLOBAL_STREAM, expected_version: :any)
      publish_events([event], stream_name: stream_name, expected_version: expected_version)
    end

    def append_to_stream(events, stream_name: GLOBAL_STREAM, expected_version: :any)
      events = normalize_to_array(events)
      events.each{|event| enrich_event_metadata(event) }
      first_stream, *other_streams = normalize_to_array(stream_name)
      @repository.append_to_stream(events, first_stream, expected_version)
      other_streams.each { |stream| link_to_stream(map_to_event_ids(events), stream_name: stream) }
      :ok
    end

    def link_to_stream(event_ids, stream_name:, expected_version: :any)
      @repository.link_to_stream(event_ids, stream_name, expected_version)
      self
    end

    def delete_stream(stream_name)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      @repository.delete_stream(stream_name)
      :ok
    end

    def read_events_forward(stream_name, start: :head, count: @page_size)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      page = Page.new(@repository, start, count)
      @repository.read_events_forward(stream_name, page.start, page.count)
    end

    def read_events_backward(stream_name, start: :head, count: @page_size)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      page = Page.new(@repository, start, count)
      @repository.read_events_backward(stream_name, page.start, page.count)
    end

    def read_stream_events_forward(stream_name)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      @repository.read_stream_events_forward(stream_name)
    end

    def read_stream_events_backward(stream_name)
      raise IncorrectStreamData if stream_name.nil? || stream_name.empty?
      @repository.read_stream_events_backward(stream_name)
    end

    def read_all_streams_forward(start: :head, count: @page_size)
      page = Page.new(@repository, start, count)
      @repository.read_all_streams_forward(page.start, page.count)
    end

    def read_all_streams_backward(start: :head, count: @page_size)
      page = Page.new(@repository, start, count)
      @repository.read_all_streams_backward(page.start, page.count)
    end

    def read_event(event_id)
      @repository.read_event(event_id)
    end

    def get_all_streams
      @repository.get_all_streams
    end


    DEPRECATED_WITHIN = "subscribe(subscriber, event_types, &task) has been deprecated. Use within(&task).subscribe(subscriber, to: event_types).call instead"
    DEPRECATED_TO = "subscribe(subscriber, event_types) has been deprecated. Use subscribe(subscriber, to: event_types) instead"
    # OLD:
    #  subscribe(subscriber, event_types, &within)
    #  subscribe(subscriber, event_types)
    # NEW:
    #  subscribe(subscriber, to:)
    #  subscribe(to:, &subscriber)
    def subscribe(subscriber = nil, event_types = nil, to: nil, &proc)
      if to
        raise ArgumentError, "subscriber must be first argument or block, cannot be both" if subscriber && proc
        raise SubscriberNotExist, "subscriber must be first argument or block" unless subscriber || proc
        raise ArgumentError, "list of event types must be second argument or named argument to: , it cannot be both" if event_types
        subscriber ||= proc
        @event_broker.add_subscriber(subscriber, to)
      else
        if proc
          warn(DEPRECATED_WITHIN)
          within(&proc).subscribe(subscriber, to: event_types).call
          -> {}
        else
          warn(DEPRECATED_TO)
          subscribe(subscriber, to: event_types)
        end
      end
    end

    DEPRECATED_ALL_WITHIN = "subscribe_to_all_events(subscriber, &task) has been deprecated. Use within(&task).subscribe_to_all_events(subscriber).call instead."
    # OLD:
    #  subscribe_to_all_events(subscriber, &within)
    #  subscribe_to_all_events(subscriber)
    # NEW:
    #  subscribe_to_all_events(subscriber)
    #  subscribe_to_all_events(&subscriber)
    def subscribe_to_all_events(subscriber = nil, &proc)
      if subscriber
        if proc
          warn(DEPRECATED_ALL_WITHIN)
          within(&proc).subscribe_to_all_events(subscriber).call
          -> {}
        else
          @event_broker.add_global_subscriber(subscriber)
        end
      else
        @event_broker.add_global_subscriber(proc)
      end
    end

    class Within
      def initialize(block, event_broker)
        @block = block
        @event_broker = event_broker
        @global_subscribers = []
        @subscribers = Hash.new {[]}
      end

      def subscribe_to_all_events(*handlers, &handler2)
        handlers << handler2 if handler2
        @global_subscribers += handlers
        self
      end

      def subscribe(handler=nil, to:, &handler2)
        raise ArgumentError if handler && handler2
        @subscribers[handler || handler2] += normalize_to_array(to)
        self
      end

      def call
        unsubs = @global_subscribers.map do |s|
          @event_broker.add_thread_global_subscriber(s)
        end
        unsubs += @subscribers.map do |handler, types|
          @event_broker.add_thread_subscriber(handler, types)
        end
        @block.call
      ensure
        unsubs.each(&:call)
      end

      private

      def normalize_to_array(objs)
        return *objs
      end
    end

    def within(&block)
      raise ArgumentError if block.nil?
      Within.new(block, @event_broker)
    end

    private

    def normalize_to_array(events)
      return *events
    end

    def enrich_event_metadata(event)
      metadata = event.metadata
      metadata[:timestamp] ||= @clock.()
      metadata.merge!(@metadata_proc.call || {}) if @metadata_proc

      # event.class.new(event_id: event.event_id, metadata: metadata, data: event.data)
    end

    def map_to_event_ids(events)
      normalize_to_array(events).map { |e| e.event_id }
    end

    class Page
      def initialize(repository, start, count)
        if start.instance_of?(Symbol)
          raise InvalidPageStart unless [:head].include?(start)
        else
          start = start.to_s
          raise InvalidPageStart if start.empty?
          raise EventNotFound.new(start) unless repository.has_event?(start)
        end
        raise InvalidPageSize unless count > 0
        @start = start
        @count = count
      end
      attr_reader :start, :count
    end

  end
end
