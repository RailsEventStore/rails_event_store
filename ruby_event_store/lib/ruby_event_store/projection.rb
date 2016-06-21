
module RubyEventStore
  class Projection
    private_class_method :new

    def self.from_stream(*streams)
      raise(ArgumentError, "At least one stream must be given") if streams.empty?
      new(streams)
    end

    def self.from_all_streams
      new
    end

    def initialize(streams = [])
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

    def call(event_store, start = :head, count = PAGE_SIZE)
      if streams.any?
        reduce_from_streams(event_store, start, count)
      else
        reduce_from_all_streams(event_store, start, count)
      end
    end

    private
    def reduce_from_streams(event_store, start, count)
      raise ArgumentError.new('Start must be an array with event ids or :head') unless (start.instance_of?(Array) && start.size === streams.size) || start === :head
      streams.zip(start_events(start)).reduce(initial_state) do |state, (stream_name, start_event_id)|
        event_store.read_events_forward(stream_name, start_event_id, count).reduce(state, &method(:transition))
      end
    end

    def reduce_from_all_streams(event_store, start, count)
      raise ArgumentError.new('Start must be valid event id or :head') unless start.instance_of?(String) || start === :head
      event_store.read_all_streams_forward(start, count).reduce(initial_state, &method(:transition))
    end

    def start_events(start)
      start === :head ? Array.new(streams.size) { :head } : start
    end

    def transition(state, event)
      handlers[event.class].(state, event)
      state
    end
  end
end
