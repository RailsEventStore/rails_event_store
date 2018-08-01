require 'concurrent'

module RubyEventStore
  class Client

    def initialize(repository:,
                   mapper: Mappers::Default.new,
                   subscriptions: PubSub::Subscriptions.new,
                   dispatcher: PubSub::Dispatcher.new,
                   page_size: PAGE_SIZE,
                   clock: ->{ Time.now.utc })
      @repository     = repository
      @mapper         = mapper
      @broker         = PubSub::Broker.new(subscriptions: subscriptions, dispatcher: dispatcher)
      @page_size      = page_size
      @clock          = clock
      @metadata       = Concurrent::ThreadLocalVar.new
    end


    # Persists events and notifies subscribed handlers about them
    #
    # @param events [Array<Event, Proto>, Event, Proto] event(s)
    # @param stream_name [String] name of the stream for persisting events.
    # @param expected_version [:any, :auto, :none, Integer] controls optimistic locking strategy. {http://railseventstore.org/docs/expected_version/ Read more}
    # @return [self]
    def publish(events, stream_name: GLOBAL_STREAM, expected_version: :any)
      enriched_events = enrich_events_metadata(events)
      serialized_events = serialize_events(enriched_events)
      append_to_stream_serialized_events(serialized_events, stream_name: stream_name, expected_version: expected_version)
      enriched_events.zip(serialized_events) do |event, serialized_event|
        with_metadata(
          correlation_id: event.metadata[:correlation_id] || event.event_id,
          causation_id:   event.event_id,
        ) do
          broker.(event, serialized_event)
        end
      end
      self
    end

    # @deprecated Use {#publish} instead
    def publish_events(events, stream_name: GLOBAL_STREAM, expected_version: :any)
      warn <<~EOW
        RubyEventStore::Client#publish_events has been deprecated.

        Use RubyEventStore::Client#publish instead
      EOW
      publish(events, stream_name: stream_name, expected_version: expected_version)
    end

    # @deprecated Use {#publish} instead
    def publish_event(event, stream_name: GLOBAL_STREAM, expected_version: :any)
      warn <<~EOW
        RubyEventStore::Client#publish_event has been deprecated.

        Use RubyEventStore::Client#publish instead
      EOW
      publish(event, stream_name: stream_name, expected_version: expected_version)
    end

    # @deprecated Use {#append} instead
    def append_to_stream(events, stream_name: GLOBAL_STREAM, expected_version: :any)
      warn <<~EOW
        RubyEventStore::Client#append_to_stream has been deprecated.

        Use RubyEventStore::Client#append instead
      EOW
      append(events, stream_name: stream_name, expected_version: expected_version)
    end

    # Persists new event(s) without notifying any subscribed handlers
    #
    # @param (see #publish)
    # @return [self]
    def append(events, stream_name: GLOBAL_STREAM, expected_version: :any)
      serialized_events = serialize_events(enrich_events_metadata(events))
      append_to_stream_serialized_events(serialized_events, stream_name: stream_name, expected_version: expected_version)
      self
    end

    # Links already persisted event(s) to a different stream.
    # Does not notify any subscribed handlers.
    #
    # @param event_ids [String, Array<String>] ids of events
    # @param stream_name (see #publish)
    # @param expected_version (see #publish)
    # @return [self]
    def link(event_ids, stream_name:, expected_version: :any)
      repository.link_to_stream(event_ids, Stream.new(stream_name), ExpectedVersion.new(expected_version))
      self
    end

    # @deprecated Use {#link} instead
    def link_to_stream(event_ids, stream_name:, expected_version: :any)
      warn <<~EOW
        RubyEventStore::Client#link_to_stream has been deprecated.

        Use RubyEventStore::Client#link instead
      EOW
      link(event_ids, stream_name: stream_name, expected_version: expected_version)
    end

    # Deletes a stream.
    # All events from the stream remain intact but they are no
    # longer linked to the stream.
    #
    # @param stream_name [String] name of the stream to be cleared.
    # @return [:ok]
    def delete_stream(stream_name)
      repository.delete_stream(Stream.new(stream_name))
      :ok
    end

    # @deprecated Use {#read} instead. {https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.30.0 More info}
    def read_events_forward(stream_name, start: :head, count: page_size)
      warn <<~EOW
        RubyEventStore::Client#read_events_forward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.stream(stream_name).limit(count).from(start).each.to_a
      EOW
      read.stream(stream_name).limit(count).from(start).each.to_a
    end

    # @deprecated Use {#read} instead. {https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.30.0 More info}
    def read_events_backward(stream_name, start: :head, count: page_size)
      warn <<~EOW
        RubyEventStore::Client#read_events_backward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.stream(stream_name).limit(count).from(start).backward.each.to_a
      EOW
      read.stream(stream_name).limit(count).from(start).backward.each.to_a
    end

    # @deprecated Use {#read} instead. {https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.30.0 More info}
    def read_stream_events_forward(stream_name)
      warn <<~EOW
        RubyEventStore::Client#read_stream_events_forward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.stream(stream_name).each.to_a
      EOW
      read.stream(stream_name).each.to_a
    end

    # @deprecated Use {#read} instead. {https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.30.0 More info}
    def read_stream_events_backward(stream_name)
      warn <<~EOW
        RubyEventStore::Client#read_stream_events_backward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.stream(stream_name).backward.each.to_a
      EOW
      read.stream(stream_name).backward.each.to_a
    end

    # @deprecated Use {#read} instead. {https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.30.0 More info}
    def read_all_streams_forward(start: :head, count: page_size)
      warn <<~EOW
        RubyEventStore::Client#read_all_streams_forward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.limit(count).from(start).each.to_a
      EOW
      read.limit(count).from(start).each.to_a
    end

    # @deprecated Use {#read} instead. {https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.30.0 More info}
    def read_all_streams_backward(start: :head, count: page_size)
      warn <<~EOW
        RubyEventStore::Client#read_all_streams_backward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.limit(count).from(start).backward.each.to_a
      EOW
      read.limit(count).from(start).backward.each.to_a
    end

    # Returns a single, persisted event based on its ID.
    #
    # @param event_id [String] event id
    # @return [Event, Proto]
    def read_event(event_id)
      deserialize_event(repository.read_event(event_id))
    end

    # Starts building a query specification for reading events.
    # {http://railseventstore.org/docs/read/ More info.}
    #
    # @return [Specification]
    def read
      Specification.new(repository, mapper)
    end

    # Subscribes a handler (subscriber) that will be invoked for published events of provided type.
    #
    # @overload subscribe(subscriber, to:)
    #   @param to [Array<Class>] types of events to subscribe
    #   @param subscriber [Object, Class] handler
    #   @return [Proc] - unsubscribe proc. Call to unsubscribe.
    #   @raise [ArgumentError, SubscriberNotExist]
    # @overload subscribe(to:, &subscriber)
    #   @param to [Array<Class>] types of events to subscribe
    #   @param subscriber [Proc] handler
    #   @return [Proc] - unsubscribe proc. Call to unsubscribe.
    #   @raise [ArgumentError, SubscriberNotExist]
    def subscribe(subscriber = nil, to:, &proc)
      raise ArgumentError, "subscriber must be first argument or block, cannot be both" if subscriber && proc
      subscriber ||= proc
      broker.add_subscription(subscriber, to)
    end

    # Subscribes a handler (subscriber) that will be invoked for all published events
    #
    # @overload subscribe_to_all_events(subscriber)
    #   @param subscriber [Object, Class] handler
    #   @return [Proc] - unsubscribe proc. Call to unsubscribe.
    #   @raise [ArgumentError, SubscriberNotExist]
    # @overload subscribe_to_all_events(&subscriber)
    #   @param subscriber [Proc] handler
    #   @return [Proc] - unsubscribe proc. Call to unsubscribe.
    #   @raise [ArgumentError, SubscriberNotExist]
    def subscribe_to_all_events(subscriber = nil, &proc)
      raise ArgumentError, "subscriber must be first argument or block, cannot be both" if subscriber && proc
      broker.add_global_subscription(subscriber || proc)
    end

    # Builder object for collecting temporary handlers (subscribers)
    # which are active only during the invocation of the provided
    # block of code.
    class Within
      def initialize(block, broker)
        @block = block
        @broker = broker
        @global_subscribers = []
        @subscribers = Hash.new {[]}
      end

      # Subscribes temporary handlers that
      # will be called for all published events.
      # The subscription is active only during the invocation
      # of the block of code provided to {Client#within}.
      # {http://railseventstore.org/docs/subscribe/#temporary-subscriptions Read more.}
      #
      # @param handlers [Object, Class] handlers passed as objects or classes
      # @param handler2 [Proc] handler passed as proc
      # @return [self]
      def subscribe_to_all_events(*handlers, &handler2)
        handlers << handler2 if handler2
        @global_subscribers += handlers
        self
      end

      # Subscribes temporary handlers that
      # will be called for published events of provided type.
      # The subscription is active only during the invocation
      # of the block of code provided to {Client#within}.
      # {http://railseventstore.org/docs/subscribe/#temporary-subscriptions Read more.}
      #
      # @overload subscribe(handler, to:)
      #   @param handler [Object, Class] handler passed as objects or classes
      #   @param to [Array<Class>] types of events to subscribe
      #   @return [self]
      # @overload subscribe(to:, &handler)
      #   @param to [Array<Class>] types of events to subscribe
      #   @param handler [Proc] handler passed as proc
      #   @return [self]
      def subscribe(handler=nil, to:, &handler2)
        raise ArgumentError if handler && handler2
        @subscribers[handler || handler2] += normalize_to_array(to)
        self
      end

      # Invokes the block of code provided to {Client#within}
      # and then unsubscribes temporary handlers.
      # {http://railseventstore.org/docs/subscribe/#temporary-subscriptions Read more.}
      #
      # @return [Object] value returned by the invoked block of code
      def call
        unsubs  = add_thread_global_subscribers
        unsubs += add_thread_subscribers
        @block.call
      ensure
        unsubs.each(&:call) if unsubs
      end

      private

      def add_thread_subscribers
        @subscribers.map do |subscriber, types|
          @broker.add_thread_subscription(subscriber, types)
        end
      end

      def add_thread_global_subscribers
        @global_subscribers.map do |subscriber|
          @broker.add_thread_global_subscription(subscriber)
        end
      end

      def normalize_to_array(objs)
        return *objs
      end
    end

    # Use for starting temporary subscriptions.
    # {http://railseventstore.org/docs/subscribe/#temporary-subscriptions Read more}
    #
    # @param block [Proc] block of code during which the temporary subscriptions will be active
    # @return [Within] builder object which collects temporary subscriptions
    def within(&block)
      raise ArgumentError if block.nil?
      Within.new(block, broker)
    end

    # Set additional metadata for all events published within the provided block
    # {http://railseventstore.org/docs/request_metadata#passing-your-own-metadata-using-with_metadata-method Read more}
    #
    # @param metadata [Hash] metadata to set for events
    # @param block [Proc] block of code during which the metadata will be added
    # @return [Object] last value returned by the provided block
    def with_metadata(metadata, &block)
      previous_metadata = metadata()
      self.metadata = previous_metadata.merge(metadata)
      block.call if block_given?
    ensure
      self.metadata = previous_metadata
    end

    # Deserialize event which was serialized for async event handlers
    # {http://railseventstore.org/docs/subscribe/#async-handlers Read more}
    #
    # @return [Event, Proto] deserialized event
    def deserialize(event_type:, event_id:, data:, metadata:)
      mapper.serialized_record_to_event(SerializedRecord.new(event_type: event_type, event_id: event_id, data: data, metadata: metadata))
    end

    # Read additional metadata which will be added for published events
    # {http://railseventstore.org/docs/request_metadata#passing-your-own-metadata-using-with_metadata-method Read more}
    #
    # @return [Hash]
    def metadata
      @metadata.value || EMPTY_HASH
    end

    EMPTY_HASH = {}.freeze
    private_constant :EMPTY_HASH

    private

    def serialize_events(events)
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

    def enrich_events_metadata(events)
      events = normalize_to_array(events)
      events.each{|event| enrich_event_metadata(event) }
      events
    end

    def enrich_event_metadata(event)
      metadata.each { |key, value| event.metadata[key] ||= value }
      event.metadata[:timestamp] ||= clock.call
    end

    def append_to_stream_serialized_events(serialized_events, stream_name:, expected_version:)
      repository.append_to_stream(serialized_events, Stream.new(stream_name), ExpectedVersion.new(expected_version))
    end

    protected

    def metadata=(value)
      @metadata.value = value
    end

    attr_reader :repository, :mapper, :broker, :clock, :page_size
  end
end
