# frozen_string_literal: true

module RubyEventStore
  module Browser
    class GetStream
      def initialize(routing:, stream_name:, related_streams_query:)
        @routing = routing
        @stream_name = stream_name
        @related_streams_query = related_streams_query
      end

      def to_h
        { data: JsonApiStream.new(stream_name, events_from_stream_url, related_streams).to_h }
      end

      private

      attr_reader :stream_name, :routing, :related_streams_query

      def events_from_stream_url
        routing.paginated_events_from_stream_url(id: stream_name)
      end

      def related_streams
        related_streams_query.call(stream_name) unless related_streams_query.equal?(DEFAULT_RELATED_STREAMS_QUERY)
      end
    end
  end
end
