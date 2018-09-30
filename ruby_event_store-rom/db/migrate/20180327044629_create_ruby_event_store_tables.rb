require 'rom/sql'

::ROM::SQL.migration do
  change do
    postgres = database_type =~ /postgres/
    sqlite   = database_type =~ /sqlite/

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

      column :created_at, DateTime, null: false, index: 'index_event_store_events_in_streams_on_created_at'

      index %i[stream position], unique: true, name: 'index_event_store_events_in_streams_on_stream_and_position'
      index %i[stream event_id], unique: true, name: 'index_event_store_events_in_streams_on_stream_and_event_id'
    end

    create_table? :event_store_events do
      if postgres
        column :id, :uuid, default: Sequel.function(:gen_random_uuid), primary_key: true
      else
        column :id, String, size: 36, null: false, primary_key: true
      end

      column :event_type, String, null: false
      column :metadata, String, text: true
      column :data, String, text: true, null: false
      column :created_at, DateTime, null: false, index: 'index_event_store_events_on_created_at'

      if sqlite # TODO: Is this relevant without ActiveRecord?
        index :id, unique: true
      end
    end
  end
end
