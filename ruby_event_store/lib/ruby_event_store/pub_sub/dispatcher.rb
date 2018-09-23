module RubyEventStore
  module PubSub
    class Dispatcher
      def call(subscriber, event, _)
        subscriber = subscriber.new if Class === subscriber
        subscriber.call(event)
      end

      def verify(subscriber)
        begin
          subscriber_instance = Class === subscriber ? subscriber.new : subscriber
        rescue ArgumentError
          return false
        end
        subscriber_instance.respond_to?(:call)
      end
    end
  end
end
