# frozen_string_literal: true

module RubyEventStore
  class Projection
    private_class_method :new

    def self.from_stream(stream_or_streams)
      streams = Array(stream_or_streams)
      raise(ArgumentError, "At least one stream must be given") if streams.empty?
      new(streams: streams)
    end

    def self.from_all_streams
      new
    end

    def initialize(streams: [])
      @streams = streams
      @handlers = {}
      @init = -> { {} }
    end

    attr_reader :streams, :handlers

    def init(handler)
      @init = handler
      self
    end

    def when(events, handler)
      Array(events).each { |event| handlers[event.to_s] = handler }

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
      streams.any? ? reduce_from_streams(event_store, start, count) : reduce_from_all_streams(event_store, start, count)
    end

    private

    def valid_starting_point?(start)
      return true unless start
      streams.any? ? (start.instance_of?(Array) && start.size === streams.size) : start.instance_of?(String)
    end

    def reduce_from_streams(event_store, start, count)
      raise ArgumentError.new("Start must be an array with event ids") unless valid_starting_point?(start)
      streams
        .zip(start_events(start))
        .map { |stream_name, start_event_id|
          read_scope(event_store, stream_name, count, start_event_id)
        }
        .then(&method(:enumerate_events_in_order_from_streams))
        .reduce(initial_state, &method(:transition))
    end

    def enumerate_events_in_order_from_streams(scopes)
      enumerators = scopes.map.with_index { |c, i| [i, c.to_enum] }.to_h
      # keep track of which enumerators are active
      active_enumerators = enumerators.map { true }

      Enumerator.new do |y|
        # Load initial candicdate values of the enumerator
        memo = enumerators.map do |i, enumerator|
          enumerator.next
        rescue StopIteration
          active_enumerators[i] = false
        end

        while active_enumerators.any? do
          value_index = begin
            memo
              .map.with_index { |e, i| [e, i] } # keep track of index
              .select { |_, i| active_enumerators[i] } # ignore memo position of stopped enumerators
              .map { |e, i| [e&.timestamp, i] } # yield the value we want to sort by
              .sort_by(&:first) # sort by that value
              .first.last # get the first result after sorting, and return the index
          end

          y.yield(memo[value_index])

          begin
            memo[value_index] = enumerators[value_index].next
          rescue StopIteration
            active_enumerators[value_index] = false
          end
        end
      end
    end

    def reduce_from_all_streams(event_store, start, count)
      raise ArgumentError.new("Start must be valid event id") unless valid_starting_point?(start)
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
