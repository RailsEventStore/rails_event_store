# frozen_string_literal: true

require "rails_event_store"

module RubyEventStore
  module OutboxRelay
    # Adds a second, async broker to RubyEventStore::Client (and subclasses such as
    # RailsEventStore::Client) without modifying ruby_event_store itself, and makes
    # every published event pass through the outbox relay.
    #
    # Included onto both RubyEventStore::Client and RailsEventStore::Client at
    # gem-load time (see ruby_event_store/outbox_relay.rb) -- not just the
    # former, even though the latter is a subclass of it. Internally this
    # prepends InstanceMethods rather than relying on plain `include`
    # semantics, so its #initialize wins over the including class's own.
    # RailsEventStore::Client#initialize has a fixed keyword list that never
    # forwards an `async_broker:` argument to `super`, so without prepending
    # InstanceMethods directly onto RailsEventStore::Client too (not just
    # inherited from RubyEventStore::Client), passing `async_broker:` to
    # RailsEventStore::Client.new would raise ArgumentError before ever
    # reaching RubyEventStore::Client's own prepended #initialize. This is why
    # `async_broker:` works identically on both classes, as documented in the
    # README.
    #
    # The tradeoff: for RailsEventStore::Client, #initialize is thus reached
    # twice per .new call (once directly, once again via
    # RailsEventStore::Client#initialize's own `super` chain reaching
    # RubyEventStore::Client's separately prepended copy) -- #initialize
    # guards against that with @async_broker_initializer_reentrant, so the
    # second, nested call skips building (and immediately discarding) an
    # unused default_async_broker.
    #
    # The decision of how an event gets delivered moves from the event to the subscriber:
    # #subscribe_sync (aliased as #subscribe, unchanged) delivers synchronously and
    # in-process exactly as before; #subscribe_async delivers exclusively through
    # the outbox relay. #publish itself is not overridden here at all -- every
    # published event is persisted with published_at: nil by EventRepositoryExtension,
    # since any event may have async subscribers -- so synchronous dispatch for
    # sync/Within subscribers is untouched. #append is overridden, to keep its own
    # documented contract of not notifying any subscribed handlers: it wraps its
    # (otherwise unmodified) super call in WithoutRelay.call, so
    # EventRepositoryExtension persists those rows already marked published --
    # the relay will never pick them up.
    module ClientExtension
      def self.included(base)
        base.prepend(InstanceMethods)
      end

      module InstanceMethods
        # @param async_broker [#call, #add_subscription] broker used for
        #   #subscribe_async subscribers and read by Relay. Defaults to
        #   RubyEventStore::ImmediateDispatcher scheduling through
        #   RailsEventStore::ActiveJobScheduler, reusing the repository's own
        #   serializer when it exposes one publicly, falling back to
        #   RubyEventStore::Serializers::YAML otherwise (e.g. InMemoryRepository,
        #   whose #serializer is private). Works identically whether called on
        #   RubyEventStore::Client or RailsEventStore::Client -- see the class
        #   comment for why RailsEventStore::Client needs InstanceMethods
        #   prepended a second time to make that so, and how this method
        #   avoids doing the underlying work twice because of it.
        def initialize(async_broker: nil, **kwargs)
          reentrant = defined?(@async_broker_initializer_reentrant)
          @async_broker_initializer_reentrant = true

          super(**kwargs)

          @async_broker = async_broker || default_async_broker unless reentrant
        end

        # @return [Object] the repository configured on this client (typically
        #   RubyEventStore::ActiveRecord::EventRepository, wrapped in
        #   RubyEventStore::InstrumentedRepository under Rails)
        def repository
          @repository
        end

        # @return [Mappers::BatchMapper]
        def mapper
          @mapper
        end

        # @return [Object] broker used for #subscribe_async subscribers; the relay
        #   dispatches through this broker
        attr_reader :async_broker

        # Persists new event(s) without notifying any subscribed handlers -- sync
        # or async. Otherwise identical to RubyEventStore::Client#append; only
        # wrapped so EventRepositoryExtension knows this insert needs no relay
        # delivery.
        #
        # @param (see RubyEventStore::Client#append)
        def append(events, stream_name: GLOBAL_STREAM, expected_version: :any)
          WithoutRelay.call { super }
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
        # of synchronously in-process. Unlike #subscribe_sync, this takes no block:
        # a block (an anonymous Proc) cannot be serialized for ActiveJob or any other
        # asynchronous processor, so the subscriber must be a named, resolvable class.
        #
        # @param subscriber [Class] the handler class delivered by the relay
        def subscribe_async(subscriber, to:)
          async_broker.add_subscription(subscriber, to.map { |event_klass| @event_type_resolver.call(event_klass) })
        end

        private

        def default_async_broker
          Broker.new(
            dispatcher: ImmediateDispatcher.new(
              scheduler: RailsEventStore::ActiveJobScheduler.new(serializer: async_serializer),
            ),
          )
        end

        def async_serializer
          repository.respond_to?(:serializer) ? repository.serializer : Serializers::YAML
        end
      end
    end
  end
end
