require "spec_helper"

module RailsEventStore
  ::RSpec.describe DefaultClientProfile do
    specify do
      expect(DefaultClientProfile.new.call("PostgreSQL"))
        .to eq(
              <<~PROFILE
                RailsEventStore::PgClient.new
            PROFILE
            )
    end

    specify do
      expect(DefaultClientProfile.new.call("postgresql"))
        .to eq(
              <<~PROFILE
                RailsEventStore::PgClient.new
            PROFILE
            )
    end

    specify do
      expect(DefaultClientProfile.new.call("sqlite3"))
        .to eq("RailsEventStore::Client.new")
    end

    specify do
      expect(DefaultClientProfile.new.call("mysql2"))
        .to eq("RailsEventStore::Client.new")
    end
  end
end