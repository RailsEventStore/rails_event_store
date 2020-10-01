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
        "#{api_url}/events"
      end

      def api_url
        "#{base_url}/api"
      end

      def streams_url
        "#{api_url}/streams"
      end

      def paginated_events_from_stream_url(id:, position: nil, direction: nil, count: nil)
        stream_name = Rack::Utils.escape(id)
        query_string = URI.encode_www_form({
          "page[position]" => position,
          "page[direction]" => direction,
          "page[count]" => count,
        }.compact)

        if query_string.empty?
          "#{api_url}/streams/#{stream_name}/relationships/events"
        else
          "#{api_url}/streams/#{stream_name}/relationships/events?#{query_string}"
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
