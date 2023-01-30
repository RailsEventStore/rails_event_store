# frozen_string_literal: true

module RubyEventStore
  module ActiveRecord
    class Event < ::ActiveRecord::Base
      self.primary_key = :id
      self.table_name = "event_store_events"

      attribute :data, :pass_through
      attribute :metadata, :pass_through
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
