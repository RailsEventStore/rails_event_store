# frozen_string_literal: true

module RubyEventStore
  module ROM
    module SQL
      class IndexViolationDetector
        MYSQL5_PKEY_ERROR   = "for key 'index_event_store_events_on_event_id'".freeze
        MYSQL8_PKEY_ERROR   = "for key 'event_store_events.index_event_store_events_on_event_id'".freeze
        POSTGRES_PKEY_ERROR = "Key (event_id)".freeze
        SQLITE3_PKEY_ERROR  = "event_store_events.event_id".freeze

        MYSQL5_INDEX_ERROR   = "for key 'index_event_store_events_in_streams_on_stream_and_event_id'".freeze
        MYSQL8_INDEX_ERROR   = "for key 'event_store_events_in_streams.index_event_store_events_in_streams_on_stream_and_event_id'".freeze
        POSTGRES_INDEX_ERROR = 'Key (stream, event_id)'.freeze
        SQLITE3_INDEX_ERROR  = 'event_store_events_in_streams.stream, event_store_events_in_streams.event_id'.freeze

        def detect(message)
          message.include?(MYSQL5_PKEY_ERROR) ||
            message.include?(MYSQL8_PKEY_ERROR) ||
            message.include?(POSTGRES_PKEY_ERROR)  ||
            message.include?(SQLITE3_PKEY_ERROR)   ||

            message.include?(MYSQL5_INDEX_ERROR)    ||
            message.include?(MYSQL8_INDEX_ERROR)    ||
            message.include?(POSTGRES_INDEX_ERROR) ||
            message.include?(SQLITE3_INDEX_ERROR)
        end
      end
    end
  end
end
