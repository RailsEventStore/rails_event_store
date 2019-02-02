
module RubyEventStore
  class Projection
    private_class_method :new

    def self.from_stream(*streams)
      raise(ArgumentError, "At least one stream must be given") if streams.empty?
      new(streams: streams)
    end

    def self.from_all_streams
      new
    end

    def initialize(streams: [])
      @streams  = streams
      @handlers = Hash.new { ->(_, _) {} }
      @init     = -> { Hash.new }
    end

    attr_reader :streams, :handlers

    def init(handler)
      @init = handler
      self
    end

    def when(events, handler)
      Array(events).each do |event|
        handlers[event] = handler
      end

      self
    end

    def initial_state
      @init.call
    end

    def current_state
      @current_state ||= initial_state
    end

    def call(event)
      handlers.fetch(event.class).(current_state, event)
    end

    def handled_events
      handlers.keys
    end

    def run(event_store, start: :begin, count: PAGE_SIZE)
      if streams.any?
        reduce_from_streams(event_store, start, count)
      else
        reduce_from_all_streams(event_store, start, count)
      end
    end

    private

    def valid_starting_point?(start)
      return true if start === :begin
      if streams.any?
        (start.instance_of?(Array) && start.size === streams.size)
      else
        start.instance_of?(String)
      end
    end

    def reduce_from_streams(event_store, start, count)
      raise ArgumentError.new('Start must be an array with event ids or :begin') unless valid_starting_point?(start)
      streams.zip(start_events(start)).reduce(initial_state) do |state, (stream_name, start_event_id)|
        event_store.read.in_batches(count).stream(stream_name).from(start_event_id).reduce(state, &method(:transition))
      end
    end

    def reduce_from_all_streams(event_store, start, count)
      raise ArgumentError.new('Start must be valid event id or :begin') unless valid_starting_point?(start)
      event_store.read.in_batches(count).from(start).reduce(initial_state, &method(:transition))
    end

    def start_events(start)
      start === :begin ? Array.new(streams.size) { :begin } : start
    end

    def transition(state, event)
      handlers[event.class].(state, event)
      state
    end
  end
end
