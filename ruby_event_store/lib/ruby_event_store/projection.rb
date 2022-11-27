# frozen_string_literal: true

module RubyEventStore
  class Projection
    ANONYMOUS_CLASS = "#<Class:".freeze

    def initialize(initial_state = nil)
      @handlers = {}
      @init = -> { initial_state }
    end

    def on(*event_klasses, &block)
      raise(ArgumentError, 'No handler block given') unless block_given?

      event_klasses.each do |event_klass|
        name = event_klass.to_s
        raise(ArgumentError, 'Anonymous class is missing name') if name.start_with? ANONYMOUS_CLASS

        @handlers[name] = ->(state, event) { block.call(state, event) }
      end
      self
    end

    def call(*scopes)
      return initial_state if handled_events.empty?

      scopes.reduce(initial_state) do |state, scope|
        scope.of_types(handled_events).reduce(state, &method(:transition))
      end
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
  end
end
