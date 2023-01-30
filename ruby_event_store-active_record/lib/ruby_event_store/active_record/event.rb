# frozen_string_literal: true

require "active_record"

module RubyEventStore
  module ActiveRecord
    class Event < ::ActiveRecord::Base
      self.primary_key = :id
      self.table_name = "event_store_events"

      if Gem::Version.new(::ActiveRecord::VERSION::STRING) >= Gem::Version.new("6.1.0")
        skip_json_serialization = ->(initial_column_type) do
          %i[json jsonb].include?(initial_column_type.type) ? ActiveModel::Type::Value.new : initial_column_type
        end

        attribute :data, skip_json_serialization
        attribute :metadata, skip_json_serialization
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
