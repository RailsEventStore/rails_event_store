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
        ensure_method_defined(subscriber)
      end

      def subscribe(subscriber, event_types)
        event_types.each do |type|
          subscribers[type] << subscriber
        end
      end

      def ensure_method_defined(subscriber)
        unless subscriber.methods.include? :handle_event
          raise MethodNotDefined.new(method_not_defined_message(subscriber))
        end
      end

      def all_subscribers_for(event_type)
        subscribers[event_type] + @global_subscribers
      end

      def method_not_defined_message(subscriber)
        "#handle_event method is not found in #{subscriber.class} subscriber. Are you sure it is a valid subscriber?"
      end
    end
  end
end
