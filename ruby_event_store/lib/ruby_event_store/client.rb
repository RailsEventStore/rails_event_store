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
      warn <<~EOW
        RubyEventStore::Client#read_events_forward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.stream(stream_name).limit(count).from(start).each.to_a
      EOW
      read.stream(stream_name).limit(count).from(start).each.to_a
    end

    def read_events_backward(stream_name, start: :head, count: page_size)
      warn <<~EOW
        RubyEventStore::Client#read_events_backward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.stream(stream_name).limit(count).from(start).backward.each.to_a
      EOW
      read.stream(stream_name).limit(count).from(start).backward.each.to_a
    end

    def read_stream_events_forward(stream_name)
      warn <<~EOW
        RubyEventStore::Client#read_stream_events_forward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.stream(stream_name).each.to_a
      EOW
      read.stream(stream_name).each.to_a
    end

    def read_stream_events_backward(stream_name)
      warn <<~EOW
        RubyEventStore::Client#read_stream_events_backward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.stream(stream_name).backward.each.to_a
      EOW
      read.stream(stream_name).backward.each.to_a
    end

    def read_all_streams_forward(start: :head, count: page_size)
      warn <<~EOW
        RubyEventStore::Client#read_all_streams_forward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.limit(count).from(start).each.to_a
      EOW
      read.limit(count).from(start).each.to_a
    end

    def read_all_streams_backward(start: :head, count: page_size)
      warn <<~EOW
        RubyEventStore::Client#read_all_streams_backward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.limit(count).from(start).backward.each.to_a
      EOW
      read.limit(count).from(start).backward.each.to_a
    end

    def read_event(event_id)
      deserialize_event(repository.read_event(event_id))
    end

    def read
      Specification.new(repository, mapper)
    end

    # subscribe(subscriber, to:)
    # subscribe(to:, &subscriber)
    def subscribe(subscriber = nil, to:, &proc)
      raise ArgumentError, "subscriber must be first argument or block, cannot be both" if subscriber && proc
      raise SubscriberNotExist, "subscriber must be first argument or block" unless subscriber || proc
      subscriber ||= proc
      event_broker.add_subscriber(subscriber, to)
    end

    # subscribe_to_all_events(subscriber)
    # subscribe_to_all_events(&subscriber)
    def subscribe_to_all_events(subscriber = nil, &proc)
      raise ArgumentError, "subscriber must be first argument or block, cannot be both" if subscriber && proc
      raise SubscriberNotExist, "subscriber must be first argument or block" unless subscriber || proc
      event_broker.add_global_subscriber(subscriber || proc)
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
      self.metadata = (previous_metadata || {}).merge(metadata)
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

    def deserialize_event(sev)
      mapper.serialized_record_to_event(sev)
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
      Thread.current["ruby_event_store_#{hash}"]
    end

    def metadata=(value)
      Thread.current["ruby_event_store_#{hash}"] = value
    end
  end
end
