# frozen_string_literal: true

module RubyEventStore
module ActiveRecord
  class WithDefaultModels
    def call
      [Event, EventInStream]
    end
  end
end
end