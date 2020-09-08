# frozen_string_literal: true

module RubyEventStore
  module NULL
    def self.dump(value)
      value
    end

    def self.load(value)
      value
    end
  end
end
