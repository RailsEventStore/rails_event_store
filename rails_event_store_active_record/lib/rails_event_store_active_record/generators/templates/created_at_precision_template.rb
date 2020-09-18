# frozen_string_literal: true

class CreatedAtPrecision < ActiveRecord::Migration<%= migration_version %>
  def change
    unless ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      change_column :event_store_events,            :created_at, :datetime, precision: 6
      change_column :event_store_events_in_streams, :created_at, :datetime, precision: 6
    end
  end
end
