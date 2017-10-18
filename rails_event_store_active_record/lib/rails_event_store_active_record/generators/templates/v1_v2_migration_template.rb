# This migration is not intended for live migration
# It assumes no data is added at that time.
# Make sure you have a backup before running on production

# 10_000_000 distinct stream names
# can cause around 2GB of usage
# make sure you can run this migration on your production system
class MigrateResSchemaV1ToV2 < ActiveRecord::Migration<%= migration_version %>
  def up
    postgres = ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
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
      RailsEventStoreActiveRecord::EventInStream.create!(
        stream: 'all',
        position: nil,
        event_id: ev.event_id,
        created_at: ev.created_at,
      ) unless ev.stream == 'all'
    end

    add_index :event_store_events_in_streams, [:stream, :position], unique: true
    add_index :event_store_events_in_streams, [:stream, :event_id], unique: true
    add_index :event_store_events_in_streams, [:created_at]

    remove_column :event_store_events, :stream
    remove_column :event_store_events, :id
    rename_column :event_store_events, :event_id, :id
    change_column :event_store_events, :id, "uuid using id::uuid" if postgres
    execute "ALTER TABLE event_store_events ADD PRIMARY KEY (id);"
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