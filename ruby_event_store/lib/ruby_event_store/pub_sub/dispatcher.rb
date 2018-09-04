module RubyEventStore
  module PubSub
    class Dispatcher
      def call(subscriber, event, _)
        subscriber = subscriber.new if Class === subscriber
        subscriber.call(event)
      end

      def verify(subscriber)
        subscriber = klassify(subscriber)
        raise InvalidHandler.new("#call method not found in #{subscriber.inspect} subscriber. Are you sure it is a valid subscriber?") if !subscriber.respond_to?(:call)
      end

      private

      def klassify(subscriber)
        Class === subscriber ? subscriber.new : subscriber
      rescue ArgumentError
        raise InvalidHandler.new("#initialize method in #{subscriber.inspect} subscriber should be allowable to use with 0 arguments. Are you sure it is a valid subscriber?")
      end
    end
  end
end
