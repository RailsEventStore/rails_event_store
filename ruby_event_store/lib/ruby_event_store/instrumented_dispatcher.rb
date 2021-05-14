# frozen_string_literal: true

module RubyEventStore
  class InstrumentedDispatcher
    def initialize(dispatcher, instrumentation)
      @dispatcher = dispatcher
      @instrumentation = instrumentation
    end

    def call(subscriber, event, record)
      instrumentation.instrument("call.dispatcher.rails_event_store", event: event, subscriber: subscriber) do
        dispatcher.call(subscriber, event, record)
      end
    end

    def verify(subscriber)
      dispatcher.verify(subscriber)
    end

    def method_missing(method_name, *arguments, **keywords, &block)
      if respond_to?(method_name)
        dispatcher.public_send(method_name, *arguments, **keywords, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private)
      dispatcher.respond_to?(method_name)
    end

    private
    attr_reader :instrumentation, :dispatcher
  end
end
