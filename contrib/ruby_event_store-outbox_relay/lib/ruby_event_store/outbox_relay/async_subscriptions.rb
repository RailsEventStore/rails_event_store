# frozen_string_literal: true

module RubyEventStore
  module OutboxRelay
    # Registry of subscribers delivered by the relay (Client#subscribe_async),
    # together with the dispatcher that delivers to them.
    #
    # Subscribers are identified by their class name, which is what gets
    # persisted in the outbox. The relay resolves a persisted name back to a
    # subscriber only through this registry, never through constant lookup, so
    # data in the outbox table can only ever reach handlers registered here.
    class AsyncSubscriptions
      # One event to hand to one subscriber.
      Delivery = Data.define(:subscriber, :event, :record)

      # @param dispatcher [#call, #verify] delivers an event to one subscriber,
      #   e.g. RubyEventStore::ImmediateDispatcher. One that also responds to
      #   #call_all is handed whole batches, see #dispatch_all
      def initialize(dispatcher:)
        @dispatcher = dispatcher
        @subscribers = Hash.new { |hash, topic| hash[topic] = {} }
      end

      # @param subscriber [Class] a named class accepted by the dispatcher
      # @param topics [Array<String>]
      # @raise [ArgumentError] when the subscriber is not a named class
      # @raise [RubyEventStore::InvalidHandler] when the dispatcher rejects it
      def add(subscriber, topics)
        name = subscriber_name(subscriber)
        raise InvalidHandler.new("Handler #{subscriber} is invalid for dispatcher #{dispatcher}") unless dispatcher.verify(subscriber)
        topics.each { |topic| @subscribers[topic][name] = subscriber }
      end

      # @return [Hash{String => Array<String>}] names of the subscribers registered for each topic
      def to_h
        @subscribers.transform_values(&:keys)
      end

      # @param topic [String]
      # @return [Array<String>] names of subscribers registered for the topic
      def names_for(topic)
        @subscribers.fetch(topic, {}).keys
      end

      # @param topic [String]
      # @param name [String]
      # @return [Class, nil] the subscriber registered under that name for the topic
      def resolve(topic, name)
        @subscribers.fetch(topic, {})[name]
      end

      # @param subscriber [Class]
      # @param event [RubyEventStore::Event]
      # @param record [RubyEventStore::Record]
      def dispatch(subscriber, event, record)
        dispatcher.call(subscriber, event, record)
      end

      # @return [Boolean] whether the dispatcher delivers whole batches at once
      def bulk?
        dispatcher.respond_to?(:call_all)
      end

      # Delivers a batch through a dispatcher that responds to #call_all, which
      # takes an Array of Delivery and returns, for each, the error that kept it
      # from being delivered, or nil.
      #
      # @param deliveries [Array<Delivery>]
      # @return [Array<Exception, nil>]
      def dispatch_all(deliveries)
        dispatcher.call_all(deliveries)
      end

      private

      attr_reader :dispatcher

      def subscriber_name(subscriber)
        raise ArgumentError, "async subscriber must be a named class, got #{subscriber.inspect}" unless Class === subscriber && subscriber.name
        subscriber.name
      end
    end
  end
end
