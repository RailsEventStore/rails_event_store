module RubyEventStore
  class Projection
    def self.from_stream(stream_name)
      new(stream_name)
    end

    def initialize(stream_name)
      @stream_name = stream_name
      @handlers    = Hash.new { ->(_, _) {} }
      @init        = -> { Hash.new }
    end

    attr_reader :stream_name, :handlers

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
      event_store.read_stream_events_forward(stream_name).reduce(initial_state) do |state, event|
        handlers[event.class].(state, event)
        state
      end
    end
  end
end
