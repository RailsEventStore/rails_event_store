# frozen_string_literal: true

module RubyEventStore
  class ComposedDispatcher
    def initialize(*dispatchers)
      @dispatchers = dispatchers
    end

    def call(subscriber, event, serialized_record)
      @dispatchers.each do |dispatcher|
        if dispatcher.verify(subscriber)
          dispatcher.call(subscriber, event, serialized_record)
          break
        end
      end
    end

    def verify(subscriber)
      @dispatchers.any? do |dispatcher|
        dispatcher.verify(subscriber)
      end
    end
  end
end
