module RubyEventStore
  class ComposedDispatcher
    def initialize(*dispatchers)
      @dispatchers = dispatchers
    end

    def call(subscriber, event, serialized_event)
      @dispatchers.each do |dispatcher|
        begin
          dispatcher.verify(subscriber)
          dispatcher.call(subscriber, event, serialized_event)
          break
        rescue RubyEventStore::InvalidHandler
        end
      end
    end

    def verify(subscriber)
      correct_dispatcher = @dispatchers.find do |dispatcher|
        begin
          dispatcher.verify(subscriber)
          true
        rescue RubyEventStore::InvalidHandler
        end
      end
      raise InvalidHandler if correct_dispatcher.nil?
    end
  end
end
