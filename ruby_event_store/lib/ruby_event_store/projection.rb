# frozen_string_literal: true

module RubyEventStore
  class Projection
    ANONYMOUS_CLASS = "#<Class:".freeze
    NEW_CONSTRUCTOR_DEPRECATION_MESSAGE = <<~EOW
      RubyEventStore::Projection.new is deprecated and will be removed in the next major release.
      Use Projection.init(initial_state) instead.
    EOW
    private_constant :ANONYMOUS_CLASS, :NEW_CONSTRUCTOR_DEPRECATION_MESSAGE

    def initialize(initial_state = nil, _internal: false)
      warn NEW_CONSTRUCTOR_DEPRECATION_MESSAGE unless _internal
      @handlers = {}
      @init = -> { initial_state }
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

    def call(scope)
      return initial_state if handled_events.empty?

      scope.of_type(handled_events).reduce(initial_state, &method(:transition))
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
