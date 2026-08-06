# frozen_string_literal: true

require "json"

module RailsEventStore
  class JSONClient < Client
    def initialize(configuration: RailsEventStore.configuration(:json), **args)
      super
    end
  end
end
