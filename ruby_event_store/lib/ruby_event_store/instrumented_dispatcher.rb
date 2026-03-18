# frozen_string_literal: true

module RubyEventStore
  class InstrumentedDispatcher
    DEPRECATION_MESSAGE = <<~EOW
      Instrumentation event names *.rails_event_store are deprecated and will be removed in the next major release.
      Use *.ruby_event_store instead.
    EOW
    private_constant :DEPRECATION_MESSAGE

    def initialize(dispatcher, instrumentation)
      @dispatcher = dispatcher
      @instrumentation = instrumentation
    end

    def call(subscriber, event, record)
      instrumentation.instrument("call.dispatcher.ruby_event_store", event: event, subscriber: subscriber) do
        deprecated_instrument("call.dispatcher.rails_event_store", event: event, subscriber: subscriber) do
          dispatcher.call(subscriber, event, record)
        end
      end
    end

    def method_missing(method_name, *arguments, **keyword_arguments, &block)
      if respond_to?(method_name)
        dispatcher.public_send(method_name, *arguments, **keyword_arguments, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private)
      dispatcher.respond_to?(method_name)
    end

    private

    attr_reader :instrumentation, :dispatcher

    def deprecated_instrument(name, payload, &block)
      canonical_name = name.sub("rails_event_store", "ruby_event_store")
      old_listeners = instrumentation.notifier.all_listeners_for(name)
      new_listeners = instrumentation.notifier.all_listeners_for(canonical_name)
      if (old_listeners - new_listeners).any?
        warn DEPRECATION_MESSAGE
        instrumentation.instrument(name, payload, &block)
      else
        yield
      end
    end
  end
end
