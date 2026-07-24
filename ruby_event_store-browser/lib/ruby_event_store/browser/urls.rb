# frozen_string_literal: true

module RubyEventStore
  module Browser
    class Urls
      def self.from_configuration(host, root_path)
        new(host, root_path)
      end

      def self.initial
        new(nil, nil)
      end

      def with_request(request)
        Urls.new(host || request.base_url, root_path || request.script_name)
      end

      attr_reader :app_url, :host, :root_path

      def initialize(host, root_path)
        @host = host
        @root_path = root_path
        @app_url = [host, root_path].compact.reduce(:+)
      end

      def stream_url(stream_name)
        "#{app_url}/streams/#{Rack::Utils.escape(stream_name)}"
      end

      def event_url(event_id)
        "#{app_url}/events/#{event_id}"
      end

      def stream_page_url(stream_name, cursor, count)
        query =
          URI.encode_www_form(
            [["page[position]", cursor[:position]], ["page[direction]", cursor[:direction]], ["page[count]", count]],
          )
        "#{stream_url(stream_name)}?#{query}"
      end

      def swimlane_url(stream_names, sort = nil)
        "#{app_url}/swimlane?#{swimlane_query(stream_names, sort)}"
      end

      def swimlane_more_url(stream_names, cursor, sort)
        "#{app_url}/swimlane/more?#{swimlane_query(stream_names, sort, [["cursor", cursor]])}"
      end

      def app_url_for(*segments, query: nil)
        path = segments.map { |segment| Rack::Utils.escape(segment) }.join("/")
        query ? "#{app_url}/#{path}?#{URI.encode_www_form(query)}" : "#{app_url}/#{path}"
      end

      def browser_js_url
        "#{app_url}/#{BROWSER_JS}"
      end

      def browser_css_url
        "#{app_url}/#{BROWSER_CSS}"
      end

      def ==(other)
        self.class.eql?(other.class) && app_url.eql?(other.app_url)
      end

      private

      def swimlane_query(stream_names, sort, extra = [])
        pairs = stream_names.map { |name| ["streams[]", name] }
        pairs.concat(extra)
        pairs << ["sort", sort] if sort
        URI.encode_www_form(pairs)
      end
    end
  end
end
