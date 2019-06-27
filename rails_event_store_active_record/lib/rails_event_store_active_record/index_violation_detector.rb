# frozen_string_literal: true

module RailsEventStoreActiveRecord
  class IndexViolationDetector

    MYSQL_PKEY_ERROR    = "for key 'PRIMARY'"
    POSTGRES_PKEY_ERROR = "event_store_events_pkey"
    SQLITE3_PKEY_ERROR  = "event_store_events.id"

    MYSQL_INDEX_ERROR    = "for key 'index_event_store_events_in_streams_on_stream_and_event_id'"
    POSTGRES_INDEX_ERROR = "Key (stream, event_id)"
    SQLITE3_INDEX_ERROR  = "event_store_events_in_streams.stream, event_store_events_in_streams.event_id"

    def detect(message)
      message.include?(MYSQL_PKEY_ERROR)     ||
      message.include?(POSTGRES_PKEY_ERROR)  ||
      message.include?(SQLITE3_PKEY_ERROR)   ||

      message.include?(MYSQL_INDEX_ERROR)    ||
      message.include?(POSTGRES_INDEX_ERROR) ||
      message.include?(SQLITE3_INDEX_ERROR)
    end
  end

  private_constant(:IndexViolationDetector)
end