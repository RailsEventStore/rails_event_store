module RubyEventStore
  module Browser
    class Urls
      attr_reader :host, :root_path

      def self.from_configuration(host, root_path)
        new(host, root_path)
      end

      def self.initial
        new(nil, nil)
      end

      def with_request(request)
        Urls.new(host || request.base_url, root_path || request.script_name)
      end

      def initialize(host, root_path)
        @host = host
        @root_path = root_path
        @base_url = [host, root_path].join
      end

      def root_url
        @base_url
      end

      def events_url
        "#{api_url}/events"
      end

      def api_url
        "#{@base_url}/api"
      end

      def streams_url
        "#{api_url}/streams"
      end

      def paginated_events_from_stream_url(id:, position: nil, direction: nil, count: nil)
        stream_name = Rack::Utils.escape(id)
        query_string =
          URI.encode_www_form(
            { "page[position]" => position, "page[direction]" => direction, "page[count]" => count }.compact
          )

        if query_string.empty?
          "#{api_url}/streams/#{stream_name}/relationships/events"
        else
          "#{api_url}/streams/#{stream_name}/relationships/events?#{query_string}"
        end
      end

      def ==(o)
        self.class == o.class && self.host == o.host && self.root_path == o.root_path
      end
    end
  end
end
