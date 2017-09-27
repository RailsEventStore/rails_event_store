require 'active_record'

module RailsEventStoreActiveRecord
  class Event < ::ActiveRecord::Base
    self.primary_key = :id
    self.table_name = 'event_store_events'
    serialize :metadata
    serialize :data
  end

  class EventInStream < ::ActiveRecord::Base
    self.primary_key = :id
    self.table_name = 'event_store_events_in_streams'
    belongs_to :event
  end
end
