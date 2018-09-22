module RubyEventStore
  class ComposedDispatcher
    def initialize
      @dispatchers = []
    end

    def add_dispatcher(dispatcher, strategy)
      # obviously would be more OOP in final version
      @dispatchers << [dispatcher, strategy]
    end

    def call(subscriber, event, serialized_event)
      @dispatchers.each do |dispatcher, strategy|
        if strategy.call(subscriber)
          dispatcher.call(subscriber, event, serialized_event)
          break
        end
      end
      raise "No matching dispatcher"
    end

    def verify(subscriber)
      @dispatchers.any? do |dispatcher, _strategy|
        dispatcher.verify(subscriber)
      end
    end
  end
end
