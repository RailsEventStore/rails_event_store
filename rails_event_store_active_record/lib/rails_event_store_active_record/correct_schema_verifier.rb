module RailsEventStoreActiveRecord

  class EventRepository
    InvalidDatabaseSchema = Class.new(StandardError)
  end

  class CorrectSchemaVerifier
    def verify
      return unless connected? && table_exists?(:event_store_events)
      return if correct_events_schema? && correct_streams_schema?
      raise_invalid_db_schema
    end

    private

    def connected?
      ActiveRecord::Base.connected?
    end

    def correct_events_schema?
      event_store_events_columns.eql?(current_columns(:event_store_events))
    end

    def correct_streams_schema?
      event_store_events_in_streams_columns.eql?(current_columns(:event_store_events_in_streams))
    end

    def table_exists?(table_name)
      ActiveRecord::Base.connection.table_exists?(table_name)
    end

    def raise_invalid_db_schema
      raise EventRepository::InvalidDatabaseSchema.new(incorrect_schema_message)
    end

    def event_store_events_columns
      %w(id event_type metadata data created_at)
    end

    def event_store_events_in_streams_columns
      %w(id stream position event_id created_at)
    end

    def current_columns(table_name)
      ActiveRecord::Base.connection.columns(table_name).map(&:name)
    end

    def incorrect_schema_message
      <<-MESSAGE
Oh no!

It seems you're using RailsEventStoreActiveRecord::EventRepository
with incompatible database schema.

See release notes how to migrate to current database schema.
      MESSAGE
    end
  end

  private_constant(:CorrectSchemaVerifier)
end
