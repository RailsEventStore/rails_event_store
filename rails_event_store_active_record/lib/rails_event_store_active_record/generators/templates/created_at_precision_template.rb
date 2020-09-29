# frozen_string_literal: true

class CreatedAtPrecision < ActiveRecord::Migration<%= migration_version %>
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
        t.datetime    :created_at,  null: false, precision: 6
      end
      add_index :event_store_events, :id, unique: true if rails_42
      add_index :event_store_events, :created_at
      add_index :event_store_events, :event_type
      execute <<-SQL
        INSERT INTO event_store_events(id, event_type, metadata, data, created_at)
        SELECT id, event_type, metadata, data, created_at FROM old_event_store_events;
      SQL
      drop_table :old_event_store_events

      rename_table :event_store_events_in_streams, :old_event_store_events_in_streams
      create_table(:event_store_events_in_streams, force: false) do |t|
        t.string      :stream,      null: false
        t.integer     :position,    null: true
        t.references  :event,       null: false, type: :string, limit: 36
        t.datetime    :created_at,  null: false, precision: 6
      end
      add_index :event_store_events_in_streams, [:stream, :position], unique: true
      add_index :event_store_events_in_streams, [:created_at]
      add_index :event_store_events_in_streams, [:stream, :event_id], unique: true

      execute <<-SQL
        INSERT INTO event_store_events_in_streams(id, stream, position, event_id, created_at)
        SELECT id, stream, position, event_id, created_at FROM old_event_store_events_in_streams;
      SQL
      drop_table :old_event_store_events_in_streams
    when "PostgreSQL"
    else
      change_column :event_store_events,            :created_at, :datetime, precision: 6
      change_column :event_store_events_in_streams, :created_at, :datetime, precision: 6
    end
  end
end
