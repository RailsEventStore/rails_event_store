require 'active_model'

module RailsEventStore
  class EventEntity
    include ::ActiveModel::Model

    attr_accessor :id, :stream, :event_type, :event_id,
                  :metadata, :data, :created_at
  end
end
