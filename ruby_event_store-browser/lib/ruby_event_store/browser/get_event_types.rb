# frozen_string_literal: true

module RubyEventStore
  module Browser
    class GetEventTypes
      def initialize(event_store:, event_types_query:)
        @event_store = event_store
        @event_types_query = event_types_query
      end

      def to_h
        {
          data: event_types.map { |event_type| JsonApiEventType.new(event_type).to_h },
        }
      end

      private

      attr_reader :event_store, :event_types_query

      def event_types
        query = event_types_query.call(event_store)
        query.call
      end
    end
  end
end
