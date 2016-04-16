module RubyEventStore
  class Projection
    attr_reader :hash, :handled_events

    def initialize(hash)
      @hash           = hash
      @handled_events = hash.keys - [:init]
    end

    def initial_state
      hash.fetch(:init).call
    end

    def transition(state, event)
      hash[event.class].call(state, event)
    end
  end
end
