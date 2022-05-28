# frozen_string_literal: true

module RubyEventStore
  module Browser
    class Event
      attr_reader :event_store, :params

      def initialize(event_store:, params:)
        @event_store = event_store
        @params      = params
      end

      def as_json
        {
          data: JsonApiEvent.new(event, parent_event_id).to_h,
        }
      end

      def event
        @event ||= event_store.read.event!(event_id)
      end

      def parent_event_id
        if event.metadata.has_key?(:causation_id)
          event_store.read.event(event.metadata.fetch(:causation_id))&.event_id
        end
      end

      def event_id
        params.fetch(:id)
      end
    end
  end
end
