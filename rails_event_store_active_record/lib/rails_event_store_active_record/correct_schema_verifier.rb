module RailsEventStoreActiveRecord

  class EventRepository
    InvalidDatabaseSchema = Class.new(StandardError)
  end

  class CorrectSchemaVerifier
    def verify
      return unless connected? && table_exists?
      raise_invalid_db_schema if legacy_columns.eql?(current_columns)
    end

    private

    def connected?
      ActiveRecord::Base.connected?
    end

    def table_exists?
      ActiveRecord::Base.connection.table_exists?(:event_store_events)
    end

    def raise_invalid_db_schema
      raise EventRepository::InvalidDatabaseSchema.new(incorrect_schema_message)
    end

    def legacy_columns
      [
        "id",
        "stream",
        "event_type",
        "event_id",
        "metadata",
        "data",
        "created_at"
      ]
    end

    def current_columns
      ActiveRecord::Base.connection.columns("event_store_events").map(&:name)
    end

    def incorrect_schema_message
      <<-MESSAGE
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

  private_constant(:CorrectSchemaVerifier)
end
