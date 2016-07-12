module RubyEventStore
  module PubSub
    class Broker
      class Dispatcher
        def call(subscriber, event)
          ensure_method_defined(subscriber)
          subscriber.call(event)
        end

        private
        def ensure_method_defined(subscriber)
          unless subscriber.respond_to?(:call)
            raise MethodNotDefined.new(method_not_defined_message(subscriber))
          end
        end

        def method_not_defined_message(subscriber)
          "#call method found in #{subscriber.class} subscriber. Are you sure it is a valid subscriber?"
        end
      end
      private_constant :Dispatcher

      DEFAULT_DISPATCHER = Dispatcher.new

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

        ->() { @global_subscribers.delete(subscriber) }
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
      end

      def subscribe(subscriber, event_types)
        event_types.each{ |type| subscribers[type] << subscriber }
        ->() {event_types.each{ |type| subscribers[type].delete(subscriber) } }
      end

      def all_subscribers_for(event_type)
        subscribers[event_type] + @global_subscribers
      end
    end
  end
end
