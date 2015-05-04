class CreateEventsTable < ActiveRecord::Migration

  def self.up
    create_table(:event_store_events) do |t|
      t.string      :stream,      null: false
      t.string      :event_type,  null: false
      t.string      :event_id,    null: false
      t.text        :metadata
      t.text        :data,        null: false
      t.datetime    :created_at,  null: false
    end
    add_index :event_store_events, :stream
    add_index :event_store_events, :event_id, unique: true
  end

  def self.down
    drop_table :event_store_events
  end
end
