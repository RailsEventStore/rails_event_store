# frozen_string_literal: true

class CreateEventStoreEvents < ActiveRecord::Migration<%= migration_version %>
  def change
    postgres = ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
    sqlite   = ActiveRecord::Base.connection.adapter_name == "SQLite"
    rails_42 = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("5.0.0")

    enable_extension "pgcrypto" if postgres
    create_table(:event_store_events_in_streams, force: false) do |t|
      t.string      :stream,      null: false
      t.integer     :position,    null: true
      if postgres
        t.references :event, null: false, type: :uuid
      else
        t.references :event, null: false, type: :string, limit: 36
      end
      t.datetime    :created_at,  null: false, precision: 6
    end
    add_index :event_store_events_in_streams, [:stream, :position], unique: true
    add_index :event_store_events_in_streams, [:created_at]
    add_index :event_store_events_in_streams, [:stream, :event_id], unique: true

    if postgres
      create_table(:event_store_events, force: false) do |t|
        t.references  :event,       null: false, type: :uuid
        t.string      :event_type,  null: false
        t.<%= data_type %>      :metadata
        t.<%= data_type %>      :data,        null: false
        t.datetime    :created_at,  null: false
      end
    else
      create_table(:event_store_events, force: false) do |t|
        t.references  :event,       null: false, type: :string, limit: 36
        t.string      :event_type,  null: false
        t.binary      :metadata
        t.binary      :data,        null: false
        t.datetime    :created_at,  null: false, precision: 6
      end
      if sqlite && rails_42
        add_index :event_store_events, :id, unique: true
      end
    end
    add_index :event_store_events, :event_id, unique: true
    add_index :event_store_events, :created_at
    add_index :event_store_events, :event_type
  end
end
