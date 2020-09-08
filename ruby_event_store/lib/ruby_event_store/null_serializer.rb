# frozen_string_literal: true

module RubyEventStore
  class NullSerializer
    def dump(value)
      value
    end

    def load(value)
      value
    end
  end
end
