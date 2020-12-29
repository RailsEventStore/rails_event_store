class NoGlobalStreamEntries < ActiveRecord::Migration<%= migration_version %>
  def change
    case ActiveRecord::Base.connection.adapter_name
    when "SQLite"
      rename_table :event_store_events, :old_event_store_events
      create_table(:event_store_events, force: false) do |t|
        t.references  :event,       null: false, type: :string, limit: 36
        t.string      :event_type,  null: false
        t.binary      :metadata
        t.binary      :data,        null: false
        t.datetime    :created_at,  precision: 6, null: false
        t.datetime    :valid_at,    precision: 6, null: true
      end
      add_index :event_store_events, :event_id, unique: true
      add_index :event_store_events, :created_at
      add_index :event_store_events, :valid_at
      add_index :event_store_events, :event_type

      execute <<-SQL
        INSERT INTO event_store_events(event_id, event_type, metadata, data, created_at)
        SELECT id, event_type, metadata, data, created_at FROM old_event_store_events;
      SQL
      drop_table :old_event_store_events
    when "PostgreSQL"
      rename_column :event_store_events, :id, :event_id
      change_column_default :event_store_events, :event_id, nil
      add_column :event_store_events, :id, :serial

      execute <<~SQL
        UPDATE event_store_events
          SET id = event_store_events_in_streams.id
          FROM event_store_events_in_streams
          WHERE event_store_events.event_id = event_store_events_in_streams.event_id AND event_store_events_in_streams.stream = 'all';
        UPDATE event_store_events
          SET id = ese.new_id
          FROM (SELECT id, row_number() OVER (ORDER BY id) AS new_id FROM event_store_events) ese
          WHERE event_store_events.id = ese.id;
        SELECT setval(pg_get_serial_sequence('event_store_events', 'id'), max(id)) FROM event_store_events;
        ALTER TABLE event_store_events DROP CONSTRAINT event_store_events_pkey;
        ALTER TABLE event_store_events ADD PRIMARY KEY (id);
      SQL
      add_index :event_store_events, :event_id, unique: true
    else
      rename_column :event_store_events, :id, :event_id
      add_column :event_store_events, :id, :integer

      execute <<-SQL
        UPDATE event_store_events
          INNER JOIN event_store_events_in_streams ON (event_store_events.event_id = event_store_events_in_streams.event_id)
          SET event_store_events.id = event_store_events_in_streams.id
          WHERE event_store_events_in_streams.stream = 'all';
      SQL
      execute "SET @row_number = 0"
      execute "UPDATE event_store_events SET event_store_events.id = (@row_number:=@row_number + 1) ORDER BY id"
      execute "ALTER TABLE event_store_events DROP PRIMARY KEY, ADD PRIMARY KEY (id), MODIFY id INT AUTO_INCREMENT"
      add_index :event_store_events, :event_id, unique: true
    end
  end
end
