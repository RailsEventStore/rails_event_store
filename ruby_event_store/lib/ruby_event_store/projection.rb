module RubyEventStore
  class Projection
    private_class_method :new

    def self.from_stream(*streams)
      raise(ArgumentError, "At least one stream must be given") if streams.empty?
      new(streams)
    end

    def initialize(streams)
      @streams  = streams
      @handlers = Hash.new { ->(_, _) {} }
      @init     = -> { Hash.new }
    end

    attr_reader :streams, :handlers

    def init(handler)
      @init = handler
      self
    end

    def when(event, handler)
      @handlers[event] = handler
      self
    end

    def initial_state
      @init.call
    end

    def current_state
      @current_state ||= initial_state
    end

    def handle_event(event)
      handlers[event.class].(current_state, event)
    end

    def handled_events
      handlers.keys
    end

    def call(event_store)
      streams.reduce(initial_state) do |state, stream|
        event_store.read_stream_events_forward(stream).reduce(state, &method(:transition))
      end
    end

    private
    def transition(state, event)
      handlers[event.class].(state, event)
      state
    end
  end
end
