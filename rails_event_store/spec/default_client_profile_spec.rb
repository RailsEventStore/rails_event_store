require "spec_helper"
require "rails_event_store/default_client_profile"

module RailsEventStore
  ::RSpec.describe DefaultClientProfile do
    specify do
      expect(DefaultClientProfile.new.call("PostgreSQL"))
        .to eq(
              <<~PROFILE
                RailsEventStore::Client.new(
                  repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL),
                  mapper: RubyEventStore::Mappers::PreserveTypesMapper.new
                )
            PROFILE
            )
    end

    specify do
      expect(DefaultClientProfile.new.call("postgresql"))
        .to eq(
              <<~PROFILE
                RailsEventStore::Client.new(
                  repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL),
                  mapper: RubyEventStore::Mappers::PreserveTypesMapper.new
                )
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