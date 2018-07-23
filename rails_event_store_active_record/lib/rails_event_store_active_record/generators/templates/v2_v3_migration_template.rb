# Make sure you have a backup before running on production
class MigrateResSchemaV2ToV3 < ActiveRecord::Migration<%= migration_version %>
  def up
    case ActiveRecord::Base.connection.adapter_name
    when "SQLite"
      rename_table :event_store_events, :old_event_store_events
      create_table(:event_store_events, id: false, force: false) do |t|
        t.string   :id,         null: false, limit: 36
        t.string   :event_type, null: false
        t.text     :metadata
        t.text     :data,       null: false
        t.datetime :created_at, null: false
        t.integer :position,    null: false, primary_key: true, auto_increment: true
      end
      add_index :event_store_events, :id, unique: true
      add_index :event_store_events, :created_at
      add_index :event_store_events, :position, unique: true
      execute <<-SQL
        INSERT INTO event_store_events(id, event_type, metadata, data, created_at)
        SELECT id, event_type, metadata, data, created_at FROM old_event_store_events;
      SQL
      drop_table :old_event_store_events
    end
  end
end
