module RubyEventStore
  module Browser
    class GetStream
      def initialize(routing:, stream_name:, related_streams_query:)
        @routing = routing
        @stream_name = stream_name
        @related_streams_query = related_streams_query
      end

      def to_h
        {
          data: {
            id: stream_name,
            type: "streams",
            attributes: {
              related_streams: related_streams
            },
            relationships: {
              events: {
                links: {
                  self: routing.paginated_events_from_stream_url(id: stream_name)
                }
              }
            }
          }
        }
      end

      private

      attr_reader :stream_name, :routing, :related_streams_query

      def related_streams
        related_streams_query.call(stream_name) unless related_streams_query.equal?(DEFAULT_RELATED_STREAMS_QUERY)
      end
    end
  end
end
