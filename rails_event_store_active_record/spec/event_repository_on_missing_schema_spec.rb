require 'spec_helper'

module RailsEventStoreActiveRecord
  RSpec.describe EventRepository do
    include SchemaHelper

    specify 'ensure no schema verification if there is no event_store_events table' do
      establish_database_connection
      ensure_no_event_store_events_table
      expect { EventRepository.new }.not_to raise_error
    end

    private

    def ensure_no_event_store_events_table
      raise if ActiveRecord::Base.connection.table_exists?(:event_store_events)
    end
  end
end
