# frozen_string_literal: true

module RailsEventStoreActiveRecord
  class WithAbstractBaseClass
    def initialize(base_klass)
      raise ArgumentError.new(
        "#{base_klass} must be an abstract class that inherits from ActiveRecord::Base"
      ) unless base_klass < ActiveRecord::Base && base_klass.abstract_class?
      @base_klass = base_klass
    end

    def call(instance_id: SecureRandom.hex)
      [
        build_event_klass(instance_id),
        build_stream_klass(instance_id),
      ]
    end

    private
    def build_event_klass(instance_id)
      Object.const_set("Event_#{instance_id}",
        Class.new(@base_klass) do
          self.primary_key = :id
          self.table_name  = 'event_store_events'
        end
      )
    end

    def build_stream_klass(instance_id)
      Object.const_set("EventInStream_#{instance_id}",
        Class.new(@base_klass) do
          self.primary_key = :id
          self.table_name = 'event_store_events_in_streams'
          belongs_to :event, primary_key: :event_id, class_name: "Event_#{instance_id}"
        end
      )
    end
  end
end
