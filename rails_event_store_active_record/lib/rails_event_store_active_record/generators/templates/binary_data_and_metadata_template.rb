# frozen_string_literal: true

class BinaryDataAndMetadata < ActiveRecord::Migration<%= migration_version %>
  def change
    rails_42 = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("5.0.0")

    case ActiveRecord::Base.connection.adapter_name
    when "SQLite"
      rename_table :event_store_events, :old_event_store_events
      create_table(:event_store_events, id: false, force: false) do |t|
        t.string :id, limit: 36, primary_key: true, null: false
        t.string      :event_type,  null: false
        t.binary      :metadata
        t.binary      :data,        null: false
        t.datetime    :created_at,  null: false
      end
      add_index :event_store_events, :id, unique: true if rails_42
      add_index :event_store_events, :created_at
      add_index :event_store_events, :event_type
      execute <<-SQL
        INSERT INTO event_store_events(id, event_type, metadata, data, created_at)
        SELECT id, event_type, metadata, data, created_at FROM old_event_store_events;
      SQL
      drop_table :old_event_store_events
    when "PostgreSQL"
      execute <<-SQL
        ALTER TABLE event_store_events ALTER COLUMN data     TYPE bytea USING convert_to(data,     'UTF8');
        ALTER TABLE event_store_events ALTER COLUMN metadata TYPE bytea USING convert_to(metadata, 'UTF8');
      SQL
    else
      change_column :event_store_events, :data,     :binary
      change_column :event_store_events, :metadata, :binary
    end
  end
end
