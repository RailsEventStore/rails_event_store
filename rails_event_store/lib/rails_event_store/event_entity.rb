require 'active_record'

module RailsEventStore
  class EventEntity < ActiveRecord::Base
    self.primary_key = :id
    self.table_name = 'event_store_events'
    serialize :metadata
    serialize :data
  end
end