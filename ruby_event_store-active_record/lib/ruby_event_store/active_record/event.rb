# frozen_string_literal: true

require "active_record"

module RubyEventStore
  module ActiveRecord
    class Event < ::ActiveRecord::Base
      self.primary_key = :id
      self.table_name = "event_store_events"

      def self.skip_json_serialization(cast_type)
        if %i[json jsonb].include?(cast_type.type)
          ActiveModel::Type::Value.new
        else
          cast_type
        end
      end

      if ::ActiveRecord.version >= Gem::Version.new("7.2.0")
        def self.hook_attribute_type(name, cast_type)
          skip_json_serialization(cast_type)
        end
      else
        attribute :data, &method(:skip_json_serialization)
        attribute :metadata, &method(:skip_json_serialization)
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
