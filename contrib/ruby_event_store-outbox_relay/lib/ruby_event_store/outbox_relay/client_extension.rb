# frozen_string_literal: true

require "rails_event_store"

module RubyEventStore
  module OutboxRelay
    # Adds a second, async broker to RubyEventStore::Client (and subclasses such as
    # RailsEventStore::Client) without modifying ruby_event_store itself, and makes
    # every published event pass through the outbox relay.
    #
    # Included onto RubyEventStore::Client at gem-load time (see
    # ruby_event_store/outbox_relay.rb), so every client -- including subclasses --
    # is extended automatically. Internally this prepends InstanceMethods rather than
    # relying on plain `include` semantics, so its #initialize wins over the one
    # RubyEventStore::Client defines. For a subclass with its own #initialize (e.g.
    # RailsEventStore::Client), InstanceMethods#initialize is reached through that
    # subclass's `super` chain, which is why an explicit `async_broker:` argument is
    # accepted by RubyEventStore::Client.new but not by RailsEventStore::Client.new
    # (whose fixed signature forwards no such keyword) -- the latter always builds the
    # default async broker.
    #
    # The decision of how an event gets delivered moves from the event to the subscriber:
    # #subscribe_sync (aliased as #subscribe, unchanged) delivers synchronously and
    # in-process exactly as before; #subscribe_async delivers exclusively through
    # the outbox relay. #publish itself is not overridden here at all -- every event
    # is persisted with published_at: nil unconditionally, by EventRepositoryExtension,
    # since any event may have async subscribers -- so synchronous dispatch for
    # sync/Within subscribers is untouched.
    module ClientExtension
      def self.included(base)
        base.prepend(InstanceMethods)
      end

      module InstanceMethods
        # @param async_broker [#call, #add_subscription] broker used for
        #   #subscribe_async subscribers and read by Relay. Defaults to
        #   RubyEventStore::ImmediateDispatcher scheduling through
        #   RailsEventStore::ActiveJobScheduler, reusing the repository's own
        #   serializer.
        def initialize(async_broker: nil, **kwargs)
          super(**kwargs)
          @async_broker = async_broker || default_async_broker
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
              scheduler: RailsEventStore::ActiveJobScheduler.new(serializer: repository.serializer),
            ),
          )
        end
      end
    end
  end
end
