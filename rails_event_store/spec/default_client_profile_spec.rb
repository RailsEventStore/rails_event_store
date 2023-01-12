require "spec_helper"

module RailsEventStore
  ::RSpec.describe DefaultClientProfile do
    specify { expect(DefaultClientProfile.new.call("PostgreSQL")).to eq("RailsEventStore::JSONClient.new") }

    specify { expect(DefaultClientProfile.new.call("postgresql")).to eq("RailsEventStore::JSONClient.new") }

    specify { expect(DefaultClientProfile.new.call("sqlite3")).to eq("RailsEventStore::Client.new") }

    specify { expect(DefaultClientProfile.new.call("mysql2")).to eq("RailsEventStore::Client.new") }
  end
end
