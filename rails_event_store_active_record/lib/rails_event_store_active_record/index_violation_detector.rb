# frozen_string_literal: true

module RailsEventStoreActiveRecord
  class IndexViolationDetector

    def initialize(event_store_events, event_store_events_in_streams)
      @mysql5_pkey_error    = "for key 'index_#{event_store_events}_on_event_id'".freeze
      @mysql8_pkey_error    = "for key '#{event_store_events}.index_#{event_store_events}_on_event_id'".freeze
      @postgres_pkey_error  = "Key (event_id)".freeze
      @sqlite3_pkey_error   = "#{event_store_events}.event_id".freeze
      @mysql5_index_error   = "for key 'index_#{event_store_events_in_streams}_on_stream_and_event_id'".freeze
      @mysql8_index_error   = "for key '#{event_store_events_in_streams}.index_#{event_store_events_in_streams}_on_stream_and_event_id'".freeze
      @postgres_index_error = "Key (stream, event_id)".freeze
      @sqlite3_index_error  = "#{event_store_events_in_streams}.stream, #{event_store_events_in_streams}.event_id".freeze
    end

    def detect(message)
        message.include?(@mysql5_pkey_error)    ||
        message.include?(@mysql8_pkey_error)    ||
        message.include?(@postgres_pkey_error)  ||
        message.include?(@sqlite3_pkey_error)   ||
        message.include?(@mysql5_index_error)   ||
        message.include?(@mysql8_index_error)   ||
        message.include?(@postgres_index_error) ||
        message.include?(@sqlite3_index_error)
    end
  end

  private_constant(:IndexViolationDetector)
end
