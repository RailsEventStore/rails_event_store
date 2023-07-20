# frozen_string_literal: true

module RubyEventStore
  module Browser
    class SearchStreams
      def initialize(event_store:, stream_name:)
        @event_store = event_store
        @stream_name = stream_name
      end

      def to_h
        {
          data: streams
        }
      end

      private

      def streams
        event_store.search_streams(stream_name).map { |stream| { id: stream.name, type: "streams" } }
      end

      attr_reader :event_store, :stream_name
    end
  end
end
