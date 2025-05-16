# frozen_string_literal: true

require "active_record"

module RubyEventStore
  module ActiveRecord
    class Event < ::ActiveRecord::Base
      self.primary_key = :id
      self.table_name = "event_store_events"

      def self.type_for_attribute(name, &block)
        initial_column_type = super

        if %i[json jsonb].include?(initial_column_type.type)
          ActiveModel::Type::Value.new
        else
          initial_column_type
        end
      end
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
