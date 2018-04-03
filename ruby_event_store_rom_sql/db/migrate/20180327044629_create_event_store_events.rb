require 'rom/sql'

::ROM::SQL.migration do
  change do
    postgres = database_type =~ /postgres/
    sqlite   = database_type =~ /sqlite/
    
    run 'CREATE EXTENSION pgcrypto;' if postgres

    create_table :event_store_events_in_streams do
      primary_key :id, type: :Bignum

      column :stream, String, null: false
      column :position, Integer, null: true

      if postgres
        column :event_id, :uuid, null: false, index: true
      else
        column :event_id, String, null: false, index: true
      end

      column :created_at, :datetime, null: false, index: true
      
      index %i[stream position], unique: true
      index %i[stream event_id], unique: true
    end

    create_table :event_store_events do
      if postgres
        column :id, :uuid, default: Sequel.function(:gen_random_uuid), primary_key: true
      else
        column :id, String, size: 36, null: false, primary_key: true
      end

      column :event_type, String, null: false
      column :metadata, String, text: true
      column :data, String, text: true, null: false
      column :created_at, :datetime, null: false, index: true

      if sqlite # TODO: Is this relevant without ActiveRecord?
        index :id, unique: true
      end
    end
  end
end
