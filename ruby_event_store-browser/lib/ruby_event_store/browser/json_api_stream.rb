# frozen_string_literal: true

module RubyEventStore
  module Browser
    class JsonApiStream
      def initialize(stream_name, events_from_stream_url, related_streams)
        @stream_name = stream_name
        @events_from_stream_url = events_from_stream_url
        @related_streams = related_streams
      end

      def to_h
        {
          id: stream_name,
          type: "streams",
          attributes: {
            related_streams: related_streams,
          },
          relationships: {
            events: {
              links: {
                self: events_from_stream_url,
              },
            },
          },
        }
      end

      private

      attr_reader :stream_name, :events_from_stream_url, :related_streams
    end
  end
end
