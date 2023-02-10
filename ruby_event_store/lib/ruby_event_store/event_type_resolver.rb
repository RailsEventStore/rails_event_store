# frozen_string_literal: true

module RubyEventStore
  EventTypeResolver = ->(value) { value.to_s }
end
