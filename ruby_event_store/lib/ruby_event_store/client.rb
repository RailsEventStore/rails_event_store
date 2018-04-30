module RubyEventStore
  class Client
    def initialize(repository:,
                   mapper: Mappers::Default.new,
                   event_broker:  PubSub::Broker.new,
                   page_size: PAGE_SIZE,
                   metadata_proc: nil,
                   clock: ->{ Time.now.utc })
      @repository     = repository
      @mapper         = mapper
      @event_broker   = event_broker
      @page_size      = page_size
      warn "`RubyEventStore::Client#metadata_proc` has been deprecated. Use `RubyEventStore::Client#with_metadata` instead." if metadata_proc
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
      events = normalize_to_array(events)
      events.each{|event| enrich_event_metadata(event) }
      repository.append_to_stream(serialized_events(events), Stream.new(stream_name), ExpectedVersion.new(expected_version))
      :ok
    end

    def link_to_stream(event_ids, stream_name:, expected_version: :any)
      repository.link_to_stream(event_ids, Stream.new(stream_name), ExpectedVersion.new(expected_version))
      self
    end

    def delete_stream(stream_name)
      repository.delete_stream(Stream.new(stream_name))
      :ok
    end

    def read_events_forward(stream_name, start: :head, count: page_size)
      deserialized_events(read.stream(stream_name).limit(count).from(start).each)
    end

    def read_events_backward(stream_name, start: :head, count: page_size)
      deserialized_events(read.stream(stream_name).limit(count).from(start).backward.each)
    end

    def read_stream_events_forward(stream_name)
      deserialized_events(read.stream(stream_name).each)
    end

    def read_stream_events_backward(stream_name)
      deserialized_events(read.stream(stream_name).backward.each)
    end

    def read_all_streams_forward(start: :head, count: page_size)
      deserialized_events(read.limit(count).from(start).each)
    end

    def read_all_streams_backward(start: :head, count: page_size)
      deserialized_events(read.limit(count).from(start).backward.each)
    end

    def read_event(event_id)
      deserialize_event(repository.read_event(event_id))
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
        event_broker.add_subscriber(subscriber, to)
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
          event_broker.add_global_subscriber(subscriber)
        end
      else
        event_broker.add_global_subscriber(proc)
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
        unsubs  = add_thread_global_subscribers
        unsubs += add_thread_subscribers
        @block.call
      ensure
        unsubs.each(&:call)
      end

      private

      def add_thread_subscribers
        @subscribers.map do |handler, types|
          @event_broker.add_thread_subscriber(handler, types)
        end
      end

      def add_thread_global_subscribers
        @global_subscribers.map do |s|
          @event_broker.add_thread_global_subscriber(s)
        end
      end

      def normalize_to_array(objs)
        return *objs
      end
    end

    def within(&block)
      raise ArgumentError if block.nil?
      Within.new(block, event_broker)
    end

    def with_metadata(metadata, &block)
      previous_metadata = metadata()
      self.metadata = metadata
      block.call if block_given?
    ensure
      self.metadata = previous_metadata
    end

    private

    def serialized_events(events)
      events.map do |ev|
        mapper.event_to_serialized_record(ev)
      end
    end

    def deserialized_events(serialized_events)
      serialized_events.map do |sev|
        deserialize_event(sev)
      end
    end

    def deserialize_event(sev)
      mapper.serialized_record_to_event(sev)
    end

    def read
      Specification.new(repository)
    end

    def normalize_to_array(events)
      return *events
    end

    def enrich_event_metadata(event)
      if metadata_proc
        md = metadata_proc.call || {}
        md.each{|k,v| event.metadata[k]=(v) }
      end
      if metadata
        metadata.each { |key, value| event.metadata[key] = value }
      end
      event.metadata[:timestamp] ||= clock.call
    end

    attr_reader :repository, :mapper, :event_broker, :clock, :metadata_proc, :page_size

    protected

    def metadata
      Thread.current[:ruby_event_store]
    end

    def metadata=(value)
      Thread.current[:ruby_event_store] = value
    end
  end
end
