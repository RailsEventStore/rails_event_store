require 'spec_helper'

module RailsEventStoreActiveRecord
  RSpec.describe EventRepository do
    include SchemaHelper

    around(:each) do |example|
      begin
        establish_database_connection
        load_legacy_database_schema
        example.run
      ensure
        drop_legacy_database
      end
    end

    specify 'ensure adapter cannot be used with legacy schema' do
      expect { EventRepository.new }.to raise_error do |error|
        expect(error).to be_kind_of(EventRepository::InvalidDatabaseSchema)
        expect(error.message).to eq(<<~MESSAGE)
            Oh no!

            It seems you're using RailsEventStoreActiveRecord::EventRepository
            with incompatible database schema.

            See release notes how to migrate to current database schema.
        MESSAGE
      end
    end

    specify 'no message when no connection to database' do
      close_database_connection
      expect { EventRepository.new }.not_to raise_error
      establish_database_connection
    end
  end
end
