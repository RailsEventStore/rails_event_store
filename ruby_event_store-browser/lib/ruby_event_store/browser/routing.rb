module RubyEventStore
  module Browser
    class Routing
      def initialize(host, root_path)
        @host = host
        @root_path = root_path
      end

      def paginated_events_from_stream_url(id:, position: nil, direction: nil, count: nil)
        base = [host, root_path].compact.join
        args = [position, direction, count].compact
        args.map! { |a| Rack::Utils.escape(a) }

        "#{base}/streams/#{id}/relationships/events/#{args.join('/')}"
      end

      private
      attr_reader :host, :root_path
    end
  end
end
