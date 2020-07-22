# frozen_string_literal: true

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
      @handlers = {}
      @init     = -> { {} }
    end

    attr_reader :streams, :handlers

    def init(handler)
      @init = handler
      self
    end

    def when(events, handler)
      Array(events).each do |event|
        handlers[event.to_s] = handler
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
      handlers.fetch(event.event_type).(current_state, event)
    end

    def handled_events
      handlers.keys
    end

    def run(event_store, start: nil, count: PAGE_SIZE)
      return initial_state if handled_events.empty?
      if streams.any?
        reduce_from_streams(event_store, start, count)
      else
        reduce_from_all_streams(event_store, start, count)
      end
    end

    private

    def valid_starting_point?(start)
      return true unless start
      if streams.any?
        (start.instance_of?(Array) && start.size === streams.size)
      else
        start.instance_of?(String)
      end
    end

    def reduce_from_streams(event_store, start, count)
      raise ArgumentError.new('Start must be an array with event ids') unless valid_starting_point?(start)
      streams.zip(start_events(start)).reduce(initial_state) do |state, (stream_name, start_event_id)|
        read_scope(event_store, stream_name, count, start_event_id).reduce(state, &method(:transition))
      end
    end

    def reduce_from_all_streams(event_store, start, count)
      raise ArgumentError.new('Start must be valid event id') unless valid_starting_point?(start)
      read_scope(event_store, nil, count, start).reduce(initial_state, &method(:transition))
    end

    def read_scope(event_store, stream, count, start)
      scope = event_store.read.in_batches(count)
      scope = scope.of_type(handled_events)
      scope = scope.stream(stream) if stream
      scope = scope.from(start) if start
      scope
    end

    def start_events(start)
      start ? start : Array.new
    end

    def transition(state, event)
      handlers.fetch(event.event_type).call(state, event)
      state
    end
  end
end
