# frozen_string_literal: true

module RubyEventStore
  module Browser
    class SearchStreams
      def initialize(event_store:, prefix:)
        @event_store = event_store
        @prefix = prefix
      end

      def to_h
        { streams: stream_names }
      end

      private

      attr_reader :event_store, :prefix

      def stream_names
        return [] if prefix.length < SEARCH_STREAMS_MIN_PREFIX_LENGTH

        event_store.search_streams(prefix, limit: SEARCH_STREAMS_LIMIT).first(SEARCH_STREAMS_LIMIT).map(&:name)
      end
    end
  end
end
