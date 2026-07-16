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
        @gem_source = GemSource.new($LOAD_PATH)
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

      def browser_js_url
        name = "ruby_event_store_browser.js"
        gem_source.from_git? ? cdn_file_url(name) : local_file_url(name)
      end

      def browser_css_url
        name = "ruby_event_store_browser.css"
        gem_source.from_git? ? cdn_file_url(name) : local_file_url(name)
      end

      def ==(other)
        self.class.eql?(other.class) && app_url.eql?(other.app_url)
      end

      private

      attr_reader :gem_source

      def local_file_url(name)
        "#{app_url}/#{name}"
      end

      def cdn_file_url(name)
        "https://cdn.railseventstore.org/#{gem_source.version}/#{name}"
      end
    end
  end
end
