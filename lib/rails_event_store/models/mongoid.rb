module RailsEventStore
  module Models
    module Mongoid
      class Event
        include ::Mongoid::Document
        include ::Mongoid::Timestamps::Created

        store_in collection: 'event_store_events'

        field :stream, type: String
        field :event_type, type: String
        field :event_id, type: String
        field :metadata, type: Hash, default: {}
        field :data, type: Hash, default: {}

        index(stream: 1)
        index({ event_id: 1 }, unique: true)
      end
    end
  end
end
