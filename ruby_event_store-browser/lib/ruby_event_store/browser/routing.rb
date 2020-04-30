module RubyEventStore
  module Browser
    class Routing
      def initialize(host, root_path)
        @host = host
        @root_path = root_path
      end

      def root_url
        base_url
      end

      def events_url
        "#{base_url}/api/events"
      end

      def streams_url
        "#{base_url}/api/streams"
      end

      def paginated_events_from_stream_url(id:, position: nil, direction: nil, count: nil)
        args = [position, direction, count].compact
        stream_name = Rack::Utils.escape(id)

        if args.empty?
          "#{base_url}/api/streams/#{stream_name}/relationships/events"
        else
          "#{base_url}/api/streams/#{stream_name}/relationships/events/#{args.join('/')}"
        end
      end

      private
      attr_reader :host, :root_path

      def base_url
        [host, root_path].join
      end
    end
  end
end
