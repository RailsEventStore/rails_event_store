# frozen_string_literal: true

class AddValidAt < ActiveRecord::Migration<%= migration_version %>
  def change
    case ActiveRecord::Base.connection.adapter_name
    when "PostgreSQL"
       add_column :event_store_events, :valid_at, :datetime, null: true
    else
       add_column :event_store_events, :valid_at, :datetime, precision: 6, null: true
    end

    add_index  :event_store_events, :valid_at
  end
end
