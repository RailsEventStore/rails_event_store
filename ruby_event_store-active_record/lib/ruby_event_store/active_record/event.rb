# frozen_string_literal: true

require "active_record"

module RubyEventStore
  module ActiveRecord
    class Event < ::ActiveRecord::Base
      self.primary_key = :id
      self.table_name = "event_store_events"

      include(
        Module.new do
          extend ActiveSupport::Concern

          skip_json_serialization = ->(cast_type) do
            %i[json jsonb].include?(cast_type.type) ? ActiveModel::Type::Value.new : cast_type
          end

          if ::ActiveRecord.version >= Gem::Version.new("7.2.0")
            class_methods do
              define_method(:hook_attribute_type) { |name, cast_type| skip_json_serialization[cast_type] }
            end
          else
            included do
              attribute :data, skip_json_serialization
              attribute :metadata, skip_json_serialization
            end
          end
        end,
      )
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
