require 'concurrent'

module RubyEventStore
  class Client

    def initialize(repository:,
                   mapper: Mappers::Default.new,
                   subscriptions: PubSub::Subscriptions.new,
                   dispatcher: PubSub::Dispatcher.new,
                   clock: ->{ Time.now.utc })
      @repository     = repository
      @mapper         = mapper
      @broker         = PubSub::Broker.new(subscriptions: subscriptions, dispatcher: dispatcher)
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

    # Deletes a stream.
    # All events from the stream remain intact but they are no
    # longer linked to the stream.
    #
    # @param stream_name [String] name of the stream to be cleared.
    # @return [self]
    def delete_stream(stream_name)
      repository.delete_stream(Stream.new(stream_name))
      self
    end

    # @deprecated Use {#read.event!(event_id)} instead. {https://github.com/RailsEventStore/rails_event_store/releases/tag/v0.33.0 More info}
    def read_event(event_id)
      warn <<~EOW
        RubyEventStore::Client#read_event(event_id) has been deprecated.
        Use `client.read.event!(event_id)` instead. Also available without
        bang - return nil when no event is found.
      EOW
      read.event!(event_id)
    end

    # Starts building a query specification for reading events.
    # {http://railseventstore.org/docs/read/ More info.}
    #
    # @return [Specification]
    def read
      Specification.new(SpecificationReader.new(repository, mapper))
    end

    # Gets list of streams where event is stored or linked
    #
    # @return [Array<Stream>] where event is stored or linked
    def streams_of(event_id)
      repository.streams_of(event_id)
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

    # Overwrite existing event(s) with the same ID.
    #
    # Does not notify any subscribed handlers.
    # Does not enrich with additional current metadata.
    # Does not allow changing which streams these events are in.
    # {http://railseventstore.org/docs/migrating_messages Read more}
    #
    # @example Add data and metadata to existing events
    #
    #   events = event_store.read.limit(10).each.to_a
    #   events.each do |ev|
    #     ev.data[:tenant_id] = 1
    #     ev.metadata[:server_id] = "eu-west-2"
    #   end
    #   event_store.overwrite(events)
    #
    # @example Change event type
    #
    #   events = event_store.read.limit(10).each.select{|ev| OldType === ev }.map do |ev|
    #     NewType.new(
    #       event_id: ev.event_id,
    #       data: ev.data,
    #       metadata: ev.metadata,
    #     )
    #   end
    #   event_store.overwrite(events)
    #
    # @param events [Array<Event, Proto>, Event, Proto] event(s) to serialize and overwrite again
    # @return [self]
    def overwrite(events_or_event)
      events = normalize_to_array(events_or_event)
      serialized_events = serialize_events(events)
      repository.update_messages(serialized_events)
      self
    end

    def inspect
      "#<#{self.class}:0x#{__id__.to_s(16)}>"
    end

    EMPTY_HASH = {}.freeze
    private_constant :EMPTY_HASH

    private

    def serialize_events(events)
      events.map do |ev|
        mapper.event_to_serialized_record(ev)
      end
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

    attr_reader :repository, :mapper, :broker, :clock
  end
end
