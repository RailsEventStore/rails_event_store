# frozen_string_literal: true

require_relative "../browser"
require "rack"
require "uri"
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
        related_streams_query: DEFAULT_RELATED_STREAMS_QUERY,
        extensions: [],
        views_root: nil
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
        warn(<<~WARN) if api_url
          Passing :api_url to RubyEventStore::Browser::App.for is deprecated.

          This option is no-op and will be removed in next major release.
        WARN

        Rack::Builder.new do
          use Rack::Static,
              urls:
                %w[
                  stimulus-3.2.2.js
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
                  ruby_event_store_browser.js
                  ruby_event_store_browser.css
                ].map { |f| ["/#{f}", f] }.to_h.merge(
                  "/#{BROWSER_JS}"  => "ruby_event_store_browser.js",
                  "/#{BROWSER_CSS}" => "ruby_event_store_browser.css",
                ),
              root: "#{__dir__}/../../../public"
          run App.new(
                event_store_locator: event_store_locator,
                related_streams_query: related_streams_query,
                host: host,
                root_path: path,
                extensions: extensions,
                views_root: views_root,
              )
        end
      end

      def initialize(event_store_locator:, related_streams_query:, host:, root_path:, extensions: [], views_root: nil)
        @event_store_locator = event_store_locator
        @related_streams_query = related_streams_query
        @extensions = extensions
        @views_root = views_root
        @routing = Urls.from_configuration(host, root_path)
      end

      def call(env)
        request = Rack::Request.new(env)
        router = Router.new(routing)

        router.add_route("GET", "/") do |_, urls|
          [302, { "location" => urls.stream_url(SERIALIZED_GLOBAL_STREAM_NAME) }, []]
        end

        router.add_route("GET", "/streams/:stream_name") do |params, urls|
          stream_name = params.fetch("stream_name")
          reader = GetEventsFromStream.new(event_store: event_store, stream_name: stream_name, page: params["page"])
          layout.page(
            "streams/show",
            urls: urls,
            stream_name: stream_name,
            title: "Stream #{stream_name}",
            events: reader.events,
            pagination:
              reader.pagination.transform_values { |cursor| urls.stream_page_url(stream_name, cursor, reader.count) },
            related_streams: related_streams_query.call(stream_name),
            extension_links: stream_extension_links(stream_name, urls),
          )
        end

        router.add_route("GET", "/events/:event_id") do |params, urls|
          event = event_store.read.event!(params.fetch("event_id"))
          metadata = format_event_metadata(event)
          parent_event =
            event_store.read.event(event.metadata.fetch(:causation_id)) if event.metadata.key?(:causation_id)

          layout.page(
            "events/show",
            urls: urls,
            event: event,
            title: "Event #{event.event_id}",
            metadata: metadata,
            streams: event_store.streams_of(event.event_id).map(&:name).sort,
            parent_event: parent_event,
            caused_by: event_store.read.stream("$by_causation_id_#{event.event_id}").backward.limit(PAGE_SIZE).to_a,
            extension_links: event_extension_links(event, urls),
          )
        end

        router.add_route("GET", "/swimlane") do |params, urls|
          stream_names, sort = swimlane_params(params)
          reader = GetEventsFromStreams.new(event_store: event_store, stream_names: stream_names, sort: sort)
          missing_stream_names = reader.missing_stream_names
          stream_names -= missing_stream_names
          layout.page(
            "swimlane/show",
            urls: urls,
            stream_names: stream_names,
            missing_stream_names: missing_stream_names,
            title: "Swimlane #{stream_names.join(', ')}",
            events: reader.events,
            sort: sort,
            more_url: (urls.swimlane_more_url(stream_names, reader.next_cursor, sort) if reader.more?),
          )
        end

        router.add_route("GET", "/swimlane/more") do |params, urls|
          stream_names, sort = swimlane_params(params)
          reader =
            GetEventsFromStreams.new(
              event_store: event_store,
              stream_names: stream_names,
              cursor: params["cursor"],
              sort: sort,
            )
          json(
            html:
              layout.partial("swimlane/_rows", urls: urls, stream_names: stream_names, events: reader.events, sort: sort),
            more_url: (urls.swimlane_more_url(stream_names, reader.next_cursor, sort) if reader.more?),
          )
        end

        extensions
          .select { |extension| extension.respond_to?(:register_routes) }
          .each { |extension| extension.register_routes(router, extension_context(extension)) }

        router.handle(request)
      rescue EventNotFound
        layout.not_found(routing.with_request(request), message: "There's no event with given ID")
      rescue Router::NoMatch
        layout.not_found(routing.with_request(request), message: "Page not found")
      end

      private

      attr_reader :event_store_locator, :related_streams_query, :routing, :extensions, :views_root

      def event_store
        event_store_locator.call
      end

      def extension_context(extension)
        ExtensionContext.new(event_store, extension_layout(extension))
      end

      def extension_layout(extension)
        extension.respond_to?(:views_root) ? layout.with_views_root(extension.views_root) : layout
      end

      def layout
        Layout.new(
          method(:extension_stylesheets),
          method(:extension_scripts),
          method(:extension_nav_links),
          views_roots: [views_root].compact,
        )
      end

      def stream_extension_links(stream_name, urls)
        extensions
          .select { |extension| extension.respond_to?(:stream_links) }
          .flat_map { |extension| extension.stream_links(stream_name, urls) }
      end

      def event_extension_links(event, urls)
        extensions
          .select { |extension| extension.respond_to?(:event_links) }
          .flat_map { |extension| extension.event_links(event, urls) }
      end

      def extension_nav_links(urls)
        extensions
          .select { |extension| extension.respond_to?(:nav_links) }
          .flat_map { |extension| extension.nav_links(urls) }
      end

      def extension_stylesheets(urls)
        extensions
          .select { |extension| extension.respond_to?(:stylesheets) }
          .flat_map { |extension| extension.stylesheets(urls) }
      end

      def extension_scripts(urls)
        extensions
          .select { |extension| extension.respond_to?(:scripts) }
          .flat_map { |extension| extension.scripts(urls) }
      end

      def format_event_metadata(event)
        event.metadata.to_h.tap do |metadata|
          %i[timestamp valid_at].each do |key|
            metadata[key] = metadata.fetch(key).iso8601(RubyEventStore::TIMESTAMP_PRECISION) if metadata.key?(key)
          end
        end
      end

      def json(body)
        [200, { "content-type" => "application/json" }, [JSON.generate(body)]]
      end

      def swimlane_params(params)
        stream_names = Array(params["streams"]).reject { |name| name.nil? || name.empty? }.uniq
        sort = ("as_of" if params["sort"] == "as_of")
        [stream_names, sort]
      end
    end
  end
end
