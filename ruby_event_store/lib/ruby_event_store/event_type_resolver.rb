# frozen_string_literal: true

module RubyEventStore
  class EventTypeResolver
    def call(value)
      value.to_s
    end
  end
end
