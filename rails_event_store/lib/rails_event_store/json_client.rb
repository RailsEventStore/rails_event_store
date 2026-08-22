# frozen_string_literal: true

module RailsEventStore
  class JSONClient < Client
    include Serialization::JSON
  end
end
