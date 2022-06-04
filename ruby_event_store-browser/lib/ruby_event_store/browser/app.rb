# frozen_string_literal: true

require_relative "../browser"
require "rack"
require "erb"
require "json"

module RubyEventStore
  module Browser
    class App
      def self.for(
        event_store_locator:,
        host: nil,
        path: nil,
        api_url: nil,
        environment: nil,
        related_streams_query: DEFAULT_RELATED_STREAMS_QUERY
      )
        Rack::Builder.new do
          use Rack::Static,
              urls: {
                "/ruby_event_store_browser.js" => "ruby_event_store_browser.js",
                "/bootstrap.js" => "bootstrap.js"
              },
              root: "#{__dir__}/../../../public"
          run App.new(
                event_store_locator: event_store_locator,
                related_streams_query: related_streams_query,
                host: host,
                root_path: path,
                api_url: api_url
              )
        end
      end

      def initialize(event_store_locator:, related_streams_query:, host:, root_path:, api_url:)
        @event_store_locator = event_store_locator
        @related_streams_query = related_streams_query
        @host = host
        @root_path = root_path
        @api_url = api_url
      end

      def call(env)
        request = Rack::Request.new(env)
        routing = Routing.new(host || request.base_url, root_path || request.script_name)
        event_store = event_store_locator.call

        case [request.request_method, request.path]
        in "GET", %r{/api/events/(.+)}
          render_json_api(Event.new(event_store: event_store, event_id: URI.decode_www_form_component($1)))
        in "GET", %r{/api/streams/(.+)/relationships/events}
          render_json_api(
            GetEventsFromStream.new(
              event_store: event_store,
              routing: routing,
              stream_name: URI.decode_www_form_component($1),
              page: request.params["page"]
            )
          )
        in "GET", %r{/api/streams/(.+)}
          render_json_api(
            GetStream.new(
              stream_name: URI.decode_www_form_component($1),
              routing: routing,
              related_streams_query: @related_streams_query
            )
          )
        in "GET", %r{/(events/.*|streams/.*)?}
          render_html(
            ERB.new(<<~HTML).result_with_hash(path: routing.root_path, browser_settings: browser_settings(routing))
              <!DOCTYPE html>
              <html>
                <head>
                  <title>RubyEventStore::Browser</title>
                  <meta name="ruby-event-store-browser-settings" content='<%= browser_settings %>'>
                </head>
                <body>
                  <script type="text/javascript" src="<%= path %>/ruby_event_store_browser.js"></script>
                  <script type="text/javascript" src="<%= path %>/bootstrap.js"></script>
                </body>
              </html>
          HTML
          )
        else
          render_404
        end
      rescue RubyEventStore::EventNotFound
        render_404
      end

      private

      attr_reader :event_store_locator, :related_streams_query, :host, :root_path, :api_url

      def render_404
        [404, {}, []]
      end

      def render_html(html)
        [200, html_content_type, [html]]
      end

      def render_json_api(body)
        [200, json_api_content_type, [JSON.dump(body.to_h)]]
      end

      def html_content_type
        { "Content-Type" => "text/html;charset=utf-8" }
      end

      def json_api_content_type
        { "Content-Type" => "application/vnd.api+json" }
      end

      def browser_settings(routing)
        JSON.dump(
          { rootUrl: routing.root_url, apiUrl: api_url || routing.api_url, resVersion: RubyEventStore::VERSION }
        )
      end
    end
  end
end
