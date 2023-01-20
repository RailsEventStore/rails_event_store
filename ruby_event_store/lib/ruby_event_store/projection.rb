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
      Enumerator.new do |y|
        enumerators = scopes.map(&:to_enum)
        # Load initial values of each enumerator
        #   and deactivate the enumerators that yielded nothing
        memo = enumerators.map.with_index do |enumerator, i|
          enumerator.next
        rescue StopIteration
          enumerators[i] = false
        end

        while enumerators.any?
          value_index = begin
            memo
              .each.with_index # keep track of index
              .select { |_, i| enumerators.fetch(i) } # skip stopped enumerators
              .map { |e, i| [e.timestamp, i] } # yield the sort value
              .min_by(&:first) # sort by that value
              .last # get the first result after sorting, and return the index
          end

          y.yield(memo.fetch(value_index))

          begin
            memo[value_index] = enumerators.fetch(value_index).next
          rescue StopIteration
            enumerators[value_index] = false
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
