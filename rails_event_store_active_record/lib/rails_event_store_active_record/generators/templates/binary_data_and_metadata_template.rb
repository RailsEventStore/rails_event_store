class BinaryDataAndMetadata < ActiveRecord::Migration<%= migration_version %>
  def change
    change_column :event_store_events, :data,     :binary
    change_column :event_store_events, :metadata, :binary
  end
end
