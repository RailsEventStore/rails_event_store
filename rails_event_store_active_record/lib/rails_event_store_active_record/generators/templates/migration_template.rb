class CreateEventStoreEvents < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table(:event_store_events_in_streams, force: false) do |t|
      t.string :stream, null: false
      t.integer :position, null: true
      t.binary :event_id, limit: 16, index: true, null: false
      t.datetime :created_at, index: true, null: false
    end
    add_index :event_store_events_in_streams, [:stream, :position], unique: true
    add_index :event_store_events_in_streams, [:stream, :event_id], unique: true

    create_table(:event_store_events, id: false, force: false) do |t|
      t.binary :id, limit: 16, index: { unique: true }, null: false
      t.string :event_type, null: false
      t.binary :serialized_data, null: false
      t.datetime :created_at, index: true, null: false
    end
  end
end
