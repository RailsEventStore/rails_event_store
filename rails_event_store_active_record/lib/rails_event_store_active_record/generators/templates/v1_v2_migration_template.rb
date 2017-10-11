# This migration is not intended for live migration
# It assumes no data is added at that time.
# Make sure you have a backup before running on production

# 10_000_000 distinct stream names
# can cause around 2GB of usage
# make sure you can run this migration on your production system
class MigrateResSchemaV1ToV2 < ActiveRecord::Migration<%= migration_version %>
  def up
    postgres = ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
    mysql    = ActiveRecord::Base.connection.adapter_name == "Mysql2"
    sqlite   = ActiveRecord::Base.connection.adapter_name == "SQLite"
    enable_extension "pgcrypto" if postgres
    create_table(:event_store_events_in_streams, force: false) do |t|
      t.string      :stream,      null: false
      t.integer     :position,    null: true
      if postgres
        t.references :event, null: false, type: :uuid
      else
        t.references :event, null: false, type: :string
      end
      t.datetime    :created_at,  null: false
    end
    streams = {}
    RailsEventStoreActiveRecord::Event.reset_column_information
    RailsEventStoreActiveRecord::Event.find_each do |ev|
      position = nil
      if preserve_positions?(ev.stream)
        streams[ev.stream] ||= -1
        position = streams[ev.stream] += 1
      end
      RailsEventStoreActiveRecord::EventInStream.create!(
        stream: ev.stream,
        position: position,
        event_id: ev.event_id,
        created_at: ev.created_at,
      )
    end

    add_index :event_store_events_in_streams, [:stream, :position], unique: true
    add_index :event_store_events_in_streams, [:stream, :event_id], unique: true
    add_index :event_store_events_in_streams, [:created_at]

    remove_index  :event_store_events, :event_type
    remove_column :event_store_events, :stream
    remove_column :event_store_events, :id
    add_column    :event_store_events, :position, :serial
    rename_column :event_store_events, :event_id, :id
    change_column :event_store_events, :id, "uuid using id::uuid", default: -> { "gen_random_uuid()" } if postgres
    change_column :event_store_events, :id, "string", limit: 36 if mysql || sqlite

    add_index :event_store_events, :position, unique: true

    case ActiveRecord::Base.connection.adapter_name
    when "SQLite"
      remove_index  :event_store_events, name: :index_event_store_events_on_id
      rename_table :event_store_events, :old_event_store_events
      create_table(:event_store_events, id: false, force: false) do |t|
        t.string :id, limit: 36,    null: false
        t.string      :event_type,  null: false
        t.text        :metadata
        t.text        :data,        null: false
        t.datetime    :created_at,  null: false
        t.integer     :position,    null: false, primary_key: true
      end
      add_index :event_store_events, :created_at
      add_index :event_store_events, :position, unique: true
      add_index :event_store_events, :id, unique: true
      execute <<-SQL
        INSERT INTO event_store_events(id, event_type, metadata, data, created_at)
        SELECT id, event_type, metadata, data, created_at FROM old_event_store_events;
      SQL
      drop_table :old_event_store_events
    else
      execute "ALTER TABLE event_store_events ADD PRIMARY KEY (id);"
      remove_index  :event_store_events, name: :index_event_store_events_on_id
    end
  end

  def preserve_positions?(stream_name)
    # return true if you use given stream for event sourcing
    # return true if you need to have a deterministic order of events
    # in that stream
    # return true if only one thread is supposed to be writing in that stream
    #
    # return false if this stream is for purely technical purposes
    # and multiple threads/processes can be publishing at given time
    # and you don't care about the exact order when reading from it
    false
  end
end