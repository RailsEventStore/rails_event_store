# frozen_string_literal: true

require "active_record"

module RubyEventStore
  module ActiveRecord
    class Event < ::ActiveRecord::Base
      self.primary_key = :id
      self.table_name = "event_store_events"
    end
    private_constant :Event

    class EventInStream < ::ActiveRecord::Base
      self.primary_key = :id
      self.table_name = "event_store_events_in_streams"
      belongs_to :event, primary_key: :event_id
    end
    private_constant :EventInStream
  end
end
