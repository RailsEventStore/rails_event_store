require 'active_record'

module RailsEventStore
  module Models
    class Event < ::ActiveRecord::Base
      self.primary_key = :id
      self.table_name = 'event_store_events'
      serialize :metadata
      serialize :data
    end
  end
end
