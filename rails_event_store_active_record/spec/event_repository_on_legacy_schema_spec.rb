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
        drop_legacy_database rescue nil
      end
    end

    specify 'ensure adapter cannot be used with legacy schema' do
      expect { EventRepository.new }.to raise_error do |error|
        expect(error).to be_kind_of(EventRepository::InvalidDatabaseSchema)
        expect(error.message).to eq(<<~MESSAGE)
            Oh no!

            It seems you're using RailsEventStoreActiveRecord::EventRepository
            with incompaible database schema.

            We've redesigned database structure in order to fix several concurrency-related
            bugs. This repository is intended to work on that improved data layout.

            We've prepared migration that would take you from old schema to new one.
            This migration must be run offline -- take that into consideration:

              rails g rails_event_store_active_record:v1_v2_migration
              rake db:migrate


            If you cannot migrate right now -- you can for some time continue using
            old repository. In order to do so:
            1. install 'rails_event_store_active_record-legacy' gem
            2. change configuration accordingly:

              require 'rails_event_store_active_record/legacy'

              config.event_store = RailsEventStore::Client.new(
                                     repository: RailsEventStoreActiveRecord::Legacy::EventRepository.new
                                   )


        MESSAGE
      end
    end

    specify 'no message when no connection to database' do
      close_database_connection
      expect { EventRepository.new }.not_to raise_error
      establish_database_connection
    end

    def close_database_connection
      ActiveRecord::Base.remove_connection
    end
  end
end
