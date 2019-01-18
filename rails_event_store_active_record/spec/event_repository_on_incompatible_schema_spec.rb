require 'spec_helper'

module RailsEventStoreActiveRecord
  RSpec.describe EventRepository do
    include SchemaHelper

    def load_legacy_database_schema
      run_support_migration('create_event_store_events', '0_18_2_migration')
    end

    def drop_table(name)
      ActiveRecord::Migration.drop_table(name)
    rescue ActiveRecord::StatementInvalid
    end

    specify 'ensure adapter cannot be used with legacy schema' do
      begin
        establish_database_connection
        load_legacy_database_schema
        expect { EventRepository.new }.to raise_error do |error|
          expect(error).to be_kind_of(EventRepository::InvalidDatabaseSchema)
          expect(error.message).to eq(<<~MESSAGE)
            Oh no!

            It seems you're using RailsEventStoreActiveRecord::EventRepository
            with incompatible database schema.

            See release notes how to migrate to current database schema.
          MESSAGE
        end
      ensure
        drop_table("event_store_events")
      end
    end

    specify 'ensure adapter cannot be used with invalid event_store_events schema' do
      begin
        establish_database_connection
        load_database_schema
        ActiveRecord::Migration.remove_column(:event_store_events, :event_type)
        expect { EventRepository.new }.to raise_error do |error|
          expect(error).to be_kind_of(EventRepository::InvalidDatabaseSchema)
          expect(error.message).to eq(<<~MESSAGE)
            Oh no!

            It seems you're using RailsEventStoreActiveRecord::EventRepository
            with incompatible database schema.

            See release notes how to migrate to current database schema.
          MESSAGE
        end
      ensure
        drop_table("event_store_events")
        drop_table("event_store_events_in_streams")
      end
    end

    specify 'ensure adapter cannot be used with invalid event_store_events_in_streams schema' do
      begin
        establish_database_connection
        load_database_schema
        ActiveRecord::Migration.remove_column(:event_store_events_in_streams, :created_at)
        expect { EventRepository.new }.to raise_error do |error|
          expect(error).to be_kind_of(EventRepository::InvalidDatabaseSchema)
          expect(error.message).to eq(<<~MESSAGE)
            Oh no!

            It seems you're using RailsEventStoreActiveRecord::EventRepository
            with incompatible database schema.

            See release notes how to migrate to current database schema.
          MESSAGE
        end
      ensure
        drop_table("event_store_events")
        drop_table("event_store_events_in_streams")
      end
    end

    specify 'no message when no connection to database' do
      close_database_connection
      expect { EventRepository.new }.not_to raise_error
      establish_database_connection
    end
  end
end
