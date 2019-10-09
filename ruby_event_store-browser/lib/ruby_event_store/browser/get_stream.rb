module RubyEventStore
  module Browser
    class GetStream
      def initialize(routing:, stream_name:)
        @routing = routing
        @stream_name = stream_name
      end

      def as_json
        {
          data: {
            id: stream_name,
            type: "streams",
            relationships: {
              events: {
                links: {
                  self: routing.paginated_events_from_stream_url(id: stream_name),
                }
              }
            }
          }
        }
      end

      private
      attr_reader :stream_name, :routing
    end
  end
end
