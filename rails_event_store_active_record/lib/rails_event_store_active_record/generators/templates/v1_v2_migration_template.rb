# This migration is not intended for live data  migration
# It assumes no data is added at when it is running.
# So stop your application servers from accepting new requests
# and processing background jobs before running

# Make sure you have a backup before running on production

# 10_000_000 distinct stream names
# can cause around 2GB of RAM usage
# make sure you can run this migration on your production system
class MigrateResSchemaV1ToV2 < ActiveRecord::Migration<%= migration_version %>
  def up
    postgres = ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
    mysql    = ActiveRecord::Base.connection.adapter_name == "Mysql2"
    sqlite   = ActiveRecord::Base.connection.adapter_name == "SQLite"
    rails_42 = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("5.0.0")
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

    remove_index  :event_store_events, :event_type
    remove_column :event_store_events, :stream
    remove_column :event_store_events, :id
    rename_column :event_store_events, :event_id, :id
    change_column :event_store_events, :id, "uuid using id::uuid", default: -> { "gen_random_uuid()" } if postgres
    change_column :event_store_events, :id, "string", limit: 36 if mysql || sqlite

    case ActiveRecord::Base.connection.adapter_name
    when "SQLite"
      remove_index  :event_store_events, name: :index_event_store_events_on_id
      rename_table :event_store_events, :old_event_store_events
      create_table(:event_store_events, id: false, force: false) do |t|
        t.string :id, limit: 36, primary_key: true, null: false
        t.string      :event_type,  null: false
        t.text        :metadata
        t.text        :data,        null: false
        t.datetime    :created_at,  null: false
      end
      add_index :event_store_events, :id, unique: true if rails_42
      add_index :event_store_events, :created_at
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
    # https://railseventstore.org/docs/expected_version/
    #
    # return true if you use given stream for event sourcing
    #   (especially with AggregateRoot gem)
    # return true if you use an Integer or :none as
    # expected_version when publishing in this stream
    #
    # return false if use use :any (the default) as expected_version
    # when publishing to this stream

    raise NotImplementedError
    # false
  end
end
