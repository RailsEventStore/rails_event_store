# frozen_string_literal: true

module RailsEventStore
  class DefaultClientProfile
    def call(adapter)
      adapter.downcase.eql?("postgresql") ? "RailsEventStore::JSONClient.new" : "RailsEventStore::Client.new"
    end
  end
end
