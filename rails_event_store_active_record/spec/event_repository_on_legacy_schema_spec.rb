require 'spec_helper'
require 'active_support/core_ext/string/strip'

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

    specify 'ensure_adapter_cannot_be_used_with_legacy_schema' do
      expect { EventRepository.new }.to raise_error do |error|
        expect(error).to be_kind_of(EventRepository::InvalidDatabaseSchema)
        expect(error.message).to eq(<<-MESSAGE.strip_heredoc)
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
            old repository. In order to do so, change configuration accordingly:

              config.event_store = RailsEventStore::Client.new(
                                     repository: RailsEventStoreActiveRecord::LegacyEventRepository.new
                                   )


        MESSAGE
      end
    end
  end
end
