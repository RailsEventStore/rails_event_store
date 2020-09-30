# frozen_string_literal: true

class AddValidAt < ActiveRecord::Migration<%= migration_version %>
  def change
    add_column :event_store_events, :valid_at, :datetime, precision: 6, null: true
    add_index  :event_store_events, :valid_at
  end
end
