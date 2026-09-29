# frozen_string_literal: true

module RubyEventStore
  module OutboxRelay
    # Adds async subscriptions to a RubyEventStore::Client subclass, without
    # touching ruby_event_store itself.
    #
    # #subscribe_sync (aliased as #subscribe, unchanged) delivers synchronously
    # and in-process exactly as before; #subscribe_async delivers exclusively
    # through the outbox relay. #publish persists, in the same transaction as
    # the events, one outbox message per (event, async subscriber of its
    # topic), then dispatches to sync subscribers exactly like the original.
    # #append is untouched and, as documented, notifies no one: it never writes
    # outbox messages.
    #
    # Include it into your own client class, or use one of the ready-made ones,
    # Client and, after requiring "ruby_event_store/outbox_relay/rails",
    # RailsClient. Requiring this gem changes no existing class.
    #
    # #publish repeats the steps of RubyEventStore::Client#publish, and relies on
    # the client's internals to do so. That is why the gem pins the major
    # version of ruby_event_store, and a spec fails should one of them go.
    module ClientExtension
      # @param async_subscriptions [AsyncSubscriptions] registry of
      #   #subscribe_async subscribers, read by the Relay. Defaults to one
      #   dispatching through ActiveJobDispatcher with the YAML serializer, the
      #   same serialization RailsEventStore::Client uses by default for its
      #   own async handlers.
      # @param outbox [Outbox] storage of pending deliveries
      def initialize(async_subscriptions: nil, outbox: nil, **kwargs)
        super(**kwargs)
        @async_subscriptions = async_subscriptions || default_async_subscriptions
        @outbox = outbox || Outbox.new
      end

      # @return [Mappers::BatchMapper]
      def mapper
        @mapper
      end

      # @return [AsyncSubscriptions]
      attr_reader :async_subscriptions

      # @return [Outbox]
      attr_reader :outbox

      # Persists event(s), together with an outbox message for every async
      # subscriber of each event's topic, then notifies sync subscribers --
      # otherwise identical to RubyEventStore::Client#publish.
      #
      # @param (see RubyEventStore::Client#publish)
      # @return [self]
      def publish(events, topic: nil, stream_name: GLOBAL_STREAM, expected_version: :any)
        enriched_events = enrich_events_metadata(events)
        records = transform(enriched_events)
        outbox.append(records, topic: topic, subscriptions: async_subscriptions, now: @clock.call) do
          append_records_to_stream(records, stream_name: stream_name, expected_version: expected_version)
        end
        enriched_events.zip(records) { |event, record| dispatch_sync(topic || event.event_type, event, record) }
        self
      end

      # Subscribes a handler invoked synchronously, in-process -- identical
      # behavior to the original #subscribe, kept below as a working alias for
      # backward compatibility.
      #
      # @param (see RubyEventStore::Client#subscribe)
      def subscribe_sync(subscriber = nil, to:, &block)
        subscribe(subscriber, to: to, &block)
      end

      # Subscribes a handler delivered exclusively by the outbox relay, instead
      # of synchronously in-process. The subscriber must be a named class: its
      # name is what the outbox stores, and it must be subscribed the same way
      # in both the application and the relay process.
      #
      # @param subscriber [Class] the handler class delivered by the relay
      def subscribe_async(subscriber, to:)
        async_subscriptions.add(subscriber, to.map { |event_klass| @event_type_resolver.call(event_klass) })
      end

      private

      def dispatch_sync(topic, event, record)
        with_metadata(correlation_id: event.metadata.fetch(:correlation_id), causation_id: event.event_id) do
          if @broker.public_method(:call).arity == 3
            @broker.call(topic, event, record)
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

      def default_async_subscriptions
        AsyncSubscriptions.new(dispatcher: ActiveJobDispatcher.new(serializer: Serializers::YAML))
      end
    end
  end
end
