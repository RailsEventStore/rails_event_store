# frozen_string_literal: true

class LimitForEventId < ActiveRecord::Migration<%= migration_version %>
  def change
    postgres = ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
    change_column(:event_store_events_in_streams, :event_id, :string, limit: 36) unless postgres
  end
end
