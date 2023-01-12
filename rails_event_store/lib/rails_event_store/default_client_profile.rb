# frozen_string_literal: true

module RailsEventStore
  class DefaultClientProfile
    def call(adapter)
      if adapter.downcase.eql?("postgresql")
        <<~PROFILE
          RailsEventStore::PgClient.new
        PROFILE
      else
        "RailsEventStore::Client.new"
      end
    end
  end
end
