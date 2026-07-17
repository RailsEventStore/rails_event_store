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

      def compare_url(primary, others)
        return stream_url(primary) if others.empty?

        "#{stream_url(primary)}?#{URI.encode_www_form(others.map { |name| ["compare[]", name] })}"
      end

      def compare_more_url(stream_names, cursor)
        query = stream_names.map { |name| ["streams[]", name] }
        query << ["cursor", cursor]
        "#{app_url}/streams/compare/more?#{URI.encode_www_form(query)}"
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
    end
  end
end
