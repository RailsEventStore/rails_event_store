require 'concurrent'

module RubyEventStore
  module PubSub
    class Broker
      def initialize
        @subscribers = Hash.new {|hsh, key| hsh[key] = [] }
        @global_subscribers = []

        @thread_global_subscribers = Concurrent::ThreadLocalVar.new([])
        @thread_subscribers = Concurrent::ThreadLocalVar.new do
          Hash.new {|hsh, key| hsh[key] = [] }
        end
      end

      def add_subscriber(subscriber, event_types)
        subscribe(subscriber, event_types)
      end

      def add_global_subscriber(subscriber)
        global_subscribers << subscriber

        ->() { global_subscribers.delete(subscriber) }
      end

      def add_thread_global_subscriber(subscriber)
        thread_global_subscribers.value += [subscriber]

        ->() { thread_global_subscribers.value -= [subscriber] }
      end

      def add_thread_subscriber(subscriber, event_types)
        event_types.each{ |type| thread_subscribers.value[type.to_s] << subscriber }
        ->() {event_types.each{ |type| thread_subscribers.value.fetch(type.to_s).delete(subscriber) } }
      end

      def all_subscribers_for(event_type)
        subscribers[event_type] +
        global_subscribers +
        thread_global_subscribers.value +
        thread_subscribers.value[event_type]
      end

      private

      def subscribe(subscriber, event_types)
        event_types.each{ |type| subscribers[type.to_s] << subscriber }
        ->() {event_types.each{ |type| subscribers.fetch(type.to_s).delete(subscriber) } }
      end

      attr_reader :subscribers, :global_subscribers, :thread_global_subscribers, :thread_subscribers
    end
  end
end
