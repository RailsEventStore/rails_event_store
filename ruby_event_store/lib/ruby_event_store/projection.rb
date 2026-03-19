# frozen_string_literal: true

module RubyEventStore
  class Projection
    ANONYMOUS_CLASS = "#<Class:".freeze
    DEPRECATION_MESSAGE = <<~EOW
      RubyEventStore::Projection from_stream/from_all_streams/init/when/run API is deprecated and will be removed in the next major release.
      Use Projection.new(initial_state).on(EventClass) { |state, event| new_state }.call(scope) instead.
    EOW
    MULTI_SCOPE_DEPRECATION_MESSAGE = <<~EOW
      Passing multiple scopes to RubyEventStore::Projection#call is deprecated and will be removed in the next major release.
      Use a single scope instead, e.g. call(event_store.read.stream("stream_name")).
    EOW
    NEW_CONSTRUCTOR_DEPRECATION_MESSAGE = <<~EOW
      RubyEventStore::Projection.new is deprecated and will be removed in the next major release.
      Use Projection.init(initial_state) instead.
    EOW
    private_constant :ANONYMOUS_CLASS, :DEPRECATION_MESSAGE, :MULTI_SCOPE_DEPRECATION_MESSAGE, :NEW_CONSTRUCTOR_DEPRECATION_MESSAGE

    def initialize(initial_state = nil, _internal: false)
      warn NEW_CONSTRUCTOR_DEPRECATION_MESSAGE unless _internal
      @handlers = {}
      @init = -> { initial_state }
      @streams = []
    end

    def self.init(initial_state = nil)
      new(initial_state, _internal: true)
    end

    def on(*event_klasses, &block)
      raise(ArgumentError, "No handler block given") unless block_given?

      event_klasses.each do |event_klass|
        name = event_klass.to_s
        raise(ArgumentError, "Anonymous class is missing name") if name.start_with? ANONYMOUS_CLASS

        @handlers[name] = ->(state, event) { block.call(state, event) }
      end
      self
    end

    def call(*scopes)
      return initial_state if handled_events.empty?

      warn MULTI_SCOPE_DEPRECATION_MESSAGE if scopes.size > 1

      scopes.reduce(initial_state) do |state, scope|
        scope.of_type(handled_events).reduce(state, &method(:transition))
      end
    end

    def self.from_stream(stream_or_streams)
      warn DEPRECATION_MESSAGE
      streams = Array(stream_or_streams)
      raise(ArgumentError, "At least one stream must be given") if streams.empty?
      projection = new(_internal: true)
      projection.instance_variable_set(:@streams, streams)
      projection
    end

    def self.from_all_streams
      warn DEPRECATION_MESSAGE
      new(_internal: true)
    end

    def init(handler)
      warn DEPRECATION_MESSAGE
      @init = handler
      self
    end

    def when(events, handler)
      warn DEPRECATION_MESSAGE
      Array(events).each do |event_klass|
        name = event_klass.to_s
        @handlers[name] = ->(state, event) { handler.call(state, event); state }
      end
      self
    end

    def run(event_store, start: nil, count: PAGE_SIZE)
      warn DEPRECATION_MESSAGE

      if @streams.any?
        raise ArgumentError, "Start must be an array with event ids" unless valid_start_for_streams?(start)
        scopes =
          @streams.zip(start || []).map do |stream, start_event_id|
            scope = event_store.read.stream(stream).in_batches(count)
            scope = scope.from(start_event_id) if start_event_id
            scope
          end
      else
        raise ArgumentError, "Start must be valid event id" unless valid_start_for_all_streams?(start)
        scope = event_store.read.in_batches(count)
        scope = scope.from(start) if start
        scopes = [scope]
      end

      call(*scopes)
    end

    private

    def initial_state
      @init.call
    end

    def handled_events
      @handlers.keys
    end

    def transition(state, event)
      @handlers.fetch(event.event_type).call(state, event)
    end

    def valid_start_for_streams?(start)
      return true unless start
      start.instance_of?(Array) && start.size == @streams.size
    end

    def valid_start_for_all_streams?(start)
      return true unless start
      start.instance_of?(String)
    end
  end
end
