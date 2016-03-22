module RubyEventStore
  module PubSub
    class Broker
      DEFAULT_DISPATCHER = ->(subscriber, event) { subscriber.handle_event(event) }

      def initialize(dispatcher = DEFAULT_DISPATCHER)
        @subscribers = Hash.new {|hsh, key| hsh[key] = [] }
        @global_subscribers = []
        @dispatcher = dispatcher
      end

      def add_subscriber(subscriber, event_types)
        verify_subscriber(subscriber)
        subscribe(subscriber, event_types)
      end

      def add_global_subscriber(subscriber)
        verify_subscriber(subscriber)
        @global_subscribers << subscriber
      end

      def notify_subscribers(event)
        all_subscribers_for(event.class).each do |subscriber|
          dispatcher.call(subscriber, event)
        end
      end

      private
      attr_reader :subscribers, :dispatcher

      def verify_subscriber(subscriber)
        raise SubscriberNotExist if subscriber.nil?
        raise MethodNotDefined unless subscriber.methods.include? :handle_event
      end

      def subscribe(subscriber, event_types)
        event_types.each do |type|
          subscribers[type] << subscriber
        end
      end

      def all_subscribers_for(event_type)
        subscribers[event_type] + @global_subscribers
      end
    end
  end
end
