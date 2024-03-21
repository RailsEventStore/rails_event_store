# frozen_string_literal: true

module RubyEventStore
  module Browser
    class GetStats
      def initialize(event_store:)
        @event_store = event_store
      end

      def to_h
        {
          meta: {
            events_in_total: events
          }
        }
      end

      private

      def events
        event_store.read.count
      end

      attr_reader :event_store
    end
  end
end
