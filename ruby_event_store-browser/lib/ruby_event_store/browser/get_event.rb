# frozen_string_literal: true

module RubyEventStore
  module Browser
    class GetEvent
      def initialize(event_store:, event_id:)
        @event_store = event_store
        @event_id = event_id
      end

      def to_h
        {
          data: [
            JsonApiEvent.new(event, parent_event_id).to_h,
            { relationships: { streams: { data: streams } } }
          ].reduce(&:merge)
        }
      end

      private

      def streams
        event_store
          .streams_of(event_id)
          .map { |stream| { "id" => stream.name, "type" => "streams" } }
      end

      attr_reader :event_store, :event_id

      def event
        @event ||= event_store.read.event!(event_id)
      end

      def parent_event_id
        if event.metadata.has_key?(:causation_id)
          event_store.read.event(event.metadata.fetch(:causation_id))&.event_id
        end
      end
    end
  end
end
