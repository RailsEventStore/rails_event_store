# frozen_string_literal: true

require "concurrent"

module RubyEventStore
  class Client
    def initialize(
      repository: InMemoryRepository.new,
      mapper: Mappers::BatchMapper.new,
      subscriptions: nil,
      dispatcher: nil,
      message_broker: nil,
      clock: default_clock,
      correlation_id_generator: default_correlation_id_generator,
      event_type_resolver: EventTypeResolver.new
    )
      @repository = repository
      @mapper = batch_mapper?(mapper) ? mapper : Mappers::BatchMapper.new(mapper)
      @broker =
        message_broker ||
          Broker.new(subscriptions: subscriptions || Subscriptions.new, dispatcher: dispatcher || Dispatcher.new)
      @clock = clock
      @metadata = Concurrent::ThreadLocalVar.new
      @correlation_id_generator = correlation_id_generator
      @event_type_resolver = event_type_resolver

      if (subscriptions || dispatcher)
        warn <<~EOW
          Passing subscriptions and dispatcher to #{self.class} has been deprecated.

          Pass it using message_broker argument. For example:

          event_store = RubyEventStore::Client.new(
            message_broker: RubyEventStore::Broker.new(
              subscriptions: RubyEventStore::Subscriptions.new,
              dispatcher: RubyEventStore::Dispatcher.new
            )
          )
        EOW
        warn <<~EOW if (message_broker)

            Because message_broker has been provided,
            arguments passed by subscriptions or dispatcher will be ignored.
          EOW
      end
    end

    def rescue_from_double_json_serialization!
      return unless @repository.respond_to? :rescue_from_double_json_serialization!
      @repository.rescue_from_double_json_serialization!
    end

    # Persists events and notifies subscribed handlers about them
    #
    # @param events [Array<Event>, Event] event(s)
    # @param stream_name [String] name of the stream for persisting events.
    # @param expected_version [:any, :auto, :none, Integer] controls optimistic locking strategy. {http://railseventstore.org/docs/expected_version/ Read more}
    # @return [self]
    def publish(events, topic: nil, stream_name: GLOBAL_STREAM, expected_version: :any)
      enriched_events = enrich_events_metadata(events)
      records = transform(enriched_events)
      append_records_to_stream(records, stream_name: stream_name, expected_version: expected_version)
      enriched_events.zip(records) do |event, record|
        with_metadata(correlation_id: event.metadata.fetch(:correlation_id), causation_id: event.event_id) do
          if @broker.public_method(:call).arity == 3
            @broker.call(topic || event.event_type, event, record)
          else
            warn <<~EOW
              Message broker shall support topics.
              Topic WILL BE IGNORED in the current broker.
              Modify the broker implementation to pass topic as an argument to broker.call method.
            EOW
            @broker.call(event, record)
          end
        end
      end
      self
    end

    # Persists new event(s) without notifying any subscribed handlers
    #
    # @param (see #publish)
    # @return [self]
    def append(events, stream_name: GLOBAL_STREAM, expected_version: :any)
      append_records_to_stream(
        transform(enrich_events_metadata(events)),
        stream_name: stream_name,
        expected_version: expected_version,
      )
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
      @repository.link_to_stream(Array(event_ids), Stream.new(stream_name), ExpectedVersion.new(expected_version))
      self
    end

    # Deletes a stream.
    # All events from the stream remain intact but they are no
    # longer linked to the stream.
    #
    # @param stream_name [String] name of the stream to be cleared.
    # @return [self]
    def delete_stream(stream_name)
      @repository.delete_stream(Stream.new(stream_name))
      self
    end

    # Starts building a query specification for reading events.
    # {http://railseventstore.org/docs/read/ More info.}
    #
    # @return [Specification]
    def read
      Specification.new(SpecificationReader.new(@repository, @mapper))
    end

    # Gets list of streams where event is stored or linked
    #
    # @return [Array<Stream>] where event is stored or linked
    def streams_of(event_id)
      @repository.streams_of(event_id)
    end

    # Gets position of the event in given stream
    #
    # The position is always nonnegative.
    # Returns nil if the event has no specific position in stream.
    # Raise error if event is not present in stream.
    #
    # @param event_id [String]
    # @param stream_name [String]
    # @return [Integer] nonnegative integer position of event in stream
    # @raise [EventNotFoundInStream]
    def position_in_stream(event_id, stream_name)
      @repository.position_in_stream(event_id, Stream.new(stream_name))
    end

    # Gets position of the event in global stream
    #
    # The position is always nonnegative.
    # Global position may have gaps, meaning, there may be event at
    # position 40, but no event at position 39.
    #
    # @param event_id [String]
    # @raise [EventNotFound]
    # @return [Integer] nonnegno ative integer position of event in global stream
    def global_position(event_id)
      @repository.global_position(event_id)
    end

    # Checks whether event is linked in given stream
    #
    # @param event_id [String]
    # @param stream_name [String]
    # @return [Boolean] true if event is linked to given stream, false otherwise
    def event_in_stream?(event_id, stream_name)
      stream = Stream.new(stream_name)
      stream.global? ? @repository.has_event?(event_id) : @repository.event_in_stream?(event_id, stream)
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
      @broker.add_subscription(subscriber, to.map { |event_klass| @event_type_resolver.call(event_klass) })
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
      @broker.add_global_subscription(subscriber || proc)
    end

    # Get list of handlers subscribed to an event
    #
    # @param to [Class, String] type of events to get list of sybscribed handlers
    # @return [Array<Object, Class>]
    def subscribers_for(event_class)
      @broker.all_subscriptions_for(@event_type_resolver.call(event_class))
    end

    # Builder object for collecting temporary handlers (subscribers)
    # which are active only during the invocation of the provided
    # block of code.
    class Within
      def initialize(block, broker, resolver)
        @block = block
        @broker = broker
        @global_subscribers = []
        @subscribers = Hash.new { [] }
        @resolver = resolver
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
      def subscribe(handler = nil, to:, &handler2)
        raise ArgumentError if handler && handler2
        @subscribers[handler || handler2] += Array(to).map { |event_klass| resolver.call(event_klass) }
        self
      end

      # Invokes the block of code provided to {Client#within}
      # and then unsubscribes temporary handlers.
      # {http://railseventstore.org/docs/subscribe/#temporary-subscriptions Read more.}
      #
      # @return [Object] value returned by the invoked block of code
      def call
        unsubs = add_thread_global_subscribers
        unsubs += add_thread_subscribers
        @block.call
      ensure
        unsubs.each(&:call) if unsubs
      end

      private

      attr_reader :resolver

      def add_thread_subscribers
        @subscribers.map { |subscriber, types| @broker.add_thread_subscription(subscriber, types) }
      end

      def add_thread_global_subscribers
        @global_subscribers.map { |subscriber| @broker.add_thread_global_subscription(subscriber) }
      end
    end

    # Use for starting temporary subscriptions.
    # {http://railseventstore.org/docs/subscribe/#temporary-subscriptions Read more}
    #
    # @param block [Proc] block of code during which the temporary subscriptions will be active
    # @return [Within] builder object which collects temporary subscriptions
    def within(&block)
      raise ArgumentError if block.nil?
      Within.new(block, @broker, @event_type_resolver)
    end

    # Set additional metadata for all events published within the provided block
    # {http://railseventstore.org/docs/request_metadata#passing-your-own-metadata-using-with_metadata-method Read more}
    #
    # @param metadata [Hash] metadata to set for events
    # @param block [Proc] block of code during which the metadata will be added
    # @return [Object] last value returned by the provided block
    def with_metadata(metadata_for_block, &block)
      previous_metadata = metadata
      self.metadata = previous_metadata.merge(metadata_for_block)
      block.call if block_given?
    ensure
      self.metadata = previous_metadata
    end

    # Deserialize event which was serialized for async event handlers
    # {http://railseventstore.org/docs/subscribe/#async-handlers Read more}
    #
    # @return [Event] deserialized event
    def deserialize(serializer:, event_type:, event_id:, data:, metadata:, timestamp: nil, valid_at: nil)
      extract_timestamp = lambda { |m| (m[:timestamp] || Time.parse(m.fetch("timestamp"))).iso8601 }

      @mapper.records_to_events(
        [
          SerializedRecord.new(
            event_type: event_type,
            event_id: event_id,
            data: data,
            metadata: metadata,
            timestamp: timestamp || timestamp_ = extract_timestamp[serializer.load(metadata)],
            valid_at: valid_at || timestamp_,
          ).deserialize(serializer),
        ],
      ).first
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
    #   events = event_store.read.limit(10).to_a
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
    # @param events [Array<Event>, Event] event(s) to serialize and overwrite again
    # @return [self]
    def overwrite(events_or_event)
      @repository.update_messages(transform(Array(events_or_event)))
      self
    end

    def inspect
      "#<#{self.class}:0x#{__id__.to_s(16)}>"
    end

    EMPTY_HASH = {}.freeze
    private_constant :EMPTY_HASH

    private

    def transform(events)
      @mapper.events_to_records(events)
    end

    def enrich_events_metadata(events)
      events = Array(events)
      events.each { |event| enrich_event_metadata(event) }
    end

    def enrich_event_metadata(event)
      metadata.each { |key, value| event.metadata[key] ||= value }
      event.metadata[:timestamp] ||= @clock.call
      event.metadata[:valid_at] ||= event.metadata.fetch(:timestamp)
      event.metadata[:correlation_id] ||= @correlation_id_generator.call
    end

    def append_records_to_stream(records, stream_name:, expected_version:)
      @repository.append_to_stream(records, Stream.new(stream_name), ExpectedVersion.new(expected_version))
    end

    protected

    def batch_mapper?(mapper)
      %i[events_to_records records_to_events].all? { |m| mapper.respond_to? m }
    end

    def metadata=(value)
      @metadata.value = value
    end

    def default_clock
      -> { Time.now.utc.round(TIMESTAMP_PRECISION) }
    end

    def default_correlation_id_generator
      -> { SecureRandom.uuid }
    end
  end
end
