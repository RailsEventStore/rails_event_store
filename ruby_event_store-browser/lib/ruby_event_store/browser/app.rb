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
        warn(<<~WARN) if environment
        Passing :environment to RubyEventStore::Browser::App.for is deprecated. 

        This option is no-op, has no effect and will be removed in next major release.
      WARN
        warn(<<~WARN) if host
        Passing :host to RubyEventStore::Browser::App.for is deprecated. 

        This option will be removed in next major release. 
        
        Host and mount points are correctly recognized from Rack environment 
        and this option is redundant.
      WARN
        warn(<<~WARN) if path
        Passing :path to RubyEventStore::Browser::App.for is deprecated. 

        This option will be removed in next major release. 

        Host and mount points are correctly recognized from Rack environment 
        and this option is redundant.
      WARN

        Rack::Builder.new do
          use Rack::Static,
              urls:
                %w[
                  bootstrap.js
                  ruby_event_store_browser.css
                  ruby_event_store_browser.js
                  android-chrome-192x192.png
                  android-chrome-512x512.png
                  apple-touch-icon.png
                  favicon.ico
                  favicon-16x16.png
                  favicon-32x32.png
                  mstile-70x70.png
                  mstile-144x144.png
                  mstile-150x150.png
                  mstile-310x150.png
                  mstile-310x310.png
                  safari-pinned-tab.svg
                ].map { |f| ["/#{f}", f] }.to_h,
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

      def initialize(
        event_store_locator:,
        related_streams_query:,
        host:,
        root_path:,
        api_url:
      )
        @event_store_locator = event_store_locator
        @related_streams_query = related_streams_query
        @routing = Urls.from_configuration(host, root_path, api_url)
      end

      def call(env)
        router = Router.new(routing)
        router.add_route("GET", "/api/events/:event_id") do |params|
          json GetEvent.new(
                 event_store: event_store,
                 event_id: params.fetch("event_id")
               )
        end
        router.add_route("GET", "/api/streams/:stream_name") do |params, urls|
          json GetStream.new(
                 stream_name: params.fetch("stream_name"),
                 routing: urls,
                 related_streams_query: related_streams_query
               )
        end
        router.add_route(
          "GET",
          "/api/streams/:stream_name/relationships/events"
        ) do |params, urls|
          json GetEventsFromStream.new(
                 event_store: event_store,
                 routing: urls,
                 stream_name: params.fetch("stream_name"),
                 page: params["page"]
               )
        end
        router.add_route("GET", "/api/search_streams/:stream_name") do |params|
          json SearchStreams.new(
                 event_store: event_store,
                 stream_name: params.fetch("stream_name")
               )
        end

        %w[/ /events/:event_id /streams/:stream_name].each do |starting_route|
          router.add_route("GET", starting_route) do |_, urls|
            erb bootstrap_html,
                browser_js_src: urls.browser_js_url,
                browser_css_src: urls.browser_css_url,
                bootstrap_js_src: urls.bootstrap_js_url,
                initial_data: {
                  rootUrl: urls.app_url,
                  apiUrl: urls.api_url,
                  resVersion: res_version
                }
          end
        end
        router.handle(Rack::Request.new(env))
      rescue EventNotFound, Router::NoMatch
        not_found
      end

      private

      attr_reader :event_store_locator, :related_streams_query, :routing

      def event_store
        event_store_locator.call
      end

      def bootstrap_html
        <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>RubyEventStore::Browser</title>
            <link type="text/css" rel="stylesheet" href="<%= browser_css_src %>">
            <meta name="ruby-event-store-browser-settings" content="<%= Rack::Utils.escape_html(JSON.dump(initial_data)) %>">
            <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png">
            <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">
            <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">
            <link rel="mask-icon" href="/safari-pinned-tab.svg" color="#5bbad5">
            <meta name="msapplication-TileColor" content="#da532c">
            <meta name="theme-color" content="#ffffff">
          </head>
          <body>
            <script type="text/javascript" src="<%= browser_js_src %>"></script>
            <script type="text/javascript" src="<%= bootstrap_js_src %>"></script>
          </body>
        </html>
        HTML
      end

      def not_found
        [404, {}, []]
      end

      def json(body)
        [
          200,
          { "content-type" => "application/vnd.api+json" },
          [JSON.dump(body.to_h)]
        ]
      end

      def erb(template, **locals)
        [
          200,
          { "content-type" => "text/html;charset=utf-8" },
          [ERB.new(template).result_with_hash(locals)]
        ]
      end

      def res_version
        RubyEventStore::VERSION
      end
    end
  end
end
