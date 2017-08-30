class CreateEventStoreEvents < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table(:event_store_events_in_streams) do |t|
      t.string      :stream,      null: false
      t.integer     :position,    null: true
      t.references  :event,       null: false, type: :uuid
      t.datetime    :created_at,  null: false
    end
    add_index :event_store_events_in_streams, [:stream, :position], unique: true
    add_index :event_store_events_in_streams, [:created_at]
    # add_index :event_store_events_in_streams, [:stream, :event_uuid], unique: true
    # add_index :event_store_events_in_streams, [:event_uuid]

    create_table(:event_store_events, id: :uuid) do |t|
      t.string      :event_type,  null: false
      t.text        :metadata
      t.text        :data,        null: false
      t.datetime    :created_at,  null: false
    end
    add_index :event_store_events, :created_at
  end
end