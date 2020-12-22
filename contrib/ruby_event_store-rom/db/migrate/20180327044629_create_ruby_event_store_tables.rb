require 'rom/sql'

::ROM::SQL.migration do
  change do
    postgres = database_type =~ /postgres/

    # set when copying migrations
    # or when running tests
    ENV['DATA_TYPE'] ||= 'text'
    data_type = ENV['DATA_TYPE'].to_sym
    data_types = postgres ? %i[text json jsonb] : %i[text]
    raise ArgumentError, "DATA_TYPE must be: #{data_types.join(', ')}" unless data_types.include?(data_type)

    run 'CREATE EXTENSION IF NOT EXISTS pgcrypto;' if postgres

    create_table? :event_store_events_in_streams do
      primary_key :id, type: :Bignum, null: false

      column :stream, String, null: false
      column :position, Integer

      if postgres
        column :event_id, :uuid, null: false
      else
        column :event_id, String, size: 36, null: false
      end

      column :created_at, DateTime, null: false, type: postgres ? 'TIMESTAMP' : 'DATETIME(6)', index: 'index_event_store_events_in_streams_on_created_at'

      index %i[stream position], unique: true, name: 'index_event_store_events_in_streams_on_stream_and_position'
      index %i[created_at],                    name: 'index_event_store_events_in_streams_on_created_at'
      index %i[stream event_id], unique: true, name: 'index_event_store_events_in_streams_on_stream_and_event_id'
    end

    create_table? :event_store_events do
      primary_key :id, type: :Bignum, null: false

      if postgres
        column :event_id, :uuid, null: false
      else
        column :event_id, String, size: 36, null: false
      end

      column :event_type, String, null: false

      if data_type =~ /json/
        column :metadata, data_type
        column :data, data_type, null: false
      else
        column :metadata, String, text: true
        column :data, String, text: true, null: false
      end

      column :created_at, DateTime, null: false, type: postgres ?  'TIMESTAMP' : 'DATETIME(6)', index: 'index_event_store_events_on_created_at'
      column :valid_at,   DateTime, null: false, type: postgres ?  'TIMESTAMP' : 'DATETIME(6)', index: 'index_event_store_events_on_valid_at'

      index %i[event_id],   unique: true, name: 'index_event_store_events_on_event_id'
      index %i[created_at],               name: 'index_event_store_events_on_created_at'
      index %i[valid_at],                 name: 'index_event_store_events_on_valid_at'
      index %i[event_type],               name: 'index_event_store_events_on_event_type'
    end
  end
end
