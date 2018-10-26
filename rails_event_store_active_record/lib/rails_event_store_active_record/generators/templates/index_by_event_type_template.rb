class IndexByEventType < ActiveRecord::Migration<%= migration_version %>
  def up
    add_index :event_store_events, :event_type unless index_exists? :event_store_events, :event_type
  end
end
