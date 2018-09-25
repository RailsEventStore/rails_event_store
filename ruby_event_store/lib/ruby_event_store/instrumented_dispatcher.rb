module RubyEventStore
  class InstrumentedDispatcher
    def initialize(dispatcher, instrumentation)
      @dispatcher = dispatcher
      @instrumentation = instrumentation
    end

    def call(subscriber, event, serialized_event)
      instrumentation.instrument("dispatch.dispatcher.rails_event_store", event: event, subscriber: subscriber) do
        dispatcher.call(subscriber, event, serialized_event)
      end
    end

    def verify(subscriber)
      dispatcher.verify(subscriber)
    end

    private
    attr_reader :instrumentation, :dispatcher
  end
end
