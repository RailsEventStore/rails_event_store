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
        extensions: []
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
              )
        end
      end

      class ExtensionContext
        attr_reader :event_store

        def initialize(event_store, stylesheets_resolver, scripts_resolver)
          @event_store = event_store
          @stylesheets_resolver = stylesheets_resolver
          @scripts_resolver = scripts_resolver
        end

        def render(template, views_root:, urls:, **locals)
          renderer = Renderer.new([views_root, Renderer::VIEWS_ROOT])
          content = renderer.render(template, urls: urls, **locals)
          [
            200,
            { "content-type" => "text/html;charset=utf-8" },
            [
              renderer.render(
                "layout",
                content: content,
                urls: urls,
                extension_stylesheets: @stylesheets_resolver.call(urls),
                extension_scripts: @scripts_resolver.call(urls),
              ),
            ],
          ]
        end

        def render_partial(template, views_root:, urls:, **locals)
          Renderer.new([views_root, Renderer::VIEWS_ROOT]).render(template, urls: urls, **locals)
        end

        def json(body)
          [200, { "content-type" => "application/json" }, [JSON.generate(body)]]
        end
      end

      def initialize(event_store_locator:, related_streams_query:, host:, root_path:, extensions: [])
        @event_store_locator = event_store_locator
        @related_streams_query = related_streams_query
        @extensions = extensions
        @routing = Urls.from_configuration(host, root_path)
      end

      def call(env)
        request = Rack::Request.new(env)
        router = Router.new(routing)

        router.add_route("GET", "/") do |_, urls|
          [302, { "location" => urls.stream_url(SERIALIZED_GLOBAL_STREAM_NAME) }, []]
        end

        router.add_route("GET", "/streams/compare/more") do |params, urls|
          stream_names = Array(params["streams"])
          reader =
            GetEventsFromStreams.new(event_store: event_store, stream_names: stream_names, cursor: params["cursor"])

          json(
            html: Renderer.new.render("streams/_rows", urls: urls, stream_names: stream_names, events: reader.events),
            more_url: (urls.compare_more_url(stream_names, reader.next_cursor) if reader.more?),
          )
        end

        router.add_route("GET", "/streams/:stream_name") do |params, urls|
          stream_name = params.fetch("stream_name")
          compare_names = Array(params["compare"]).reject { |name| name.nil? || name.empty? }

          if compare_names.any?
            stream_names = ([stream_name] + compare_names).uniq
            reader = GetEventsFromStreams.new(event_store: event_store, stream_names: stream_names)

            html render(
                   "streams/compare",
                   urls: urls,
                   stream_names: stream_names,
                   events: reader.events,
                   more_url: (urls.compare_more_url(stream_names, reader.next_cursor) if reader.more?),
                 )
          else
            reader = GetEventsFromStream.new(event_store: event_store, stream_name: stream_name, page: params["page"])
            html render(
                   "streams/show",
                   urls: urls,
                   stream_name: stream_name,
                   events: reader.events,
                   pagination:
                     reader.pagination.transform_values { |cursor|
                       urls.stream_page_url(stream_name, cursor, reader.count)
                     },
                   related_streams: related_streams_query.call(stream_name),
                   extension_links: extension_links(stream_name, urls),
                 )
          end
        end

        router.add_route("GET", "/events/:event_id") do |params, urls|
          event = event_store.read.event!(params.fetch("event_id"))
          metadata = format_event_metadata(event)
          parent_event =
            event_store.read.event(event.metadata.fetch(:causation_id)) if event.metadata.key?(:causation_id)

          html render(
                 "events/show",
                 urls: urls,
                 event: event,
                 metadata: metadata,
                 streams: event_store.streams_of(event.event_id).map(&:name).sort,
                 parent_event: parent_event,
                 caused_by:
                   event_store.read.stream("$by_causation_id_#{event.event_id}").backward.limit(PAGE_SIZE).to_a,
               )
        end

        extensions.each do |extension|
          extension.register_routes(router, ExtensionContext.new(event_store, method(:extension_stylesheets), method(:extension_scripts)))
        end

        router.handle(request)
      rescue EventNotFound
        not_found(routing.with_request(request))
      rescue Router::NoMatch
        [404, {}, []]
      end

      private

      attr_reader :event_store_locator, :related_streams_query, :routing, :extensions

      def event_store
        event_store_locator.call
      end

      def extension_links(stream_name, urls)
        extensions
          .select { |extension| extension.respond_to?(:stream_links) }
          .flat_map { |extension| extension.stream_links(stream_name, urls) }
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

      def render(template, urls:, **locals)
        renderer = Renderer.new
        content = renderer.render(template, urls: urls, **locals)
        renderer.render(
          "layout",
          content: content,
          urls: urls,
          extension_stylesheets: extension_stylesheets(urls),
          extension_scripts: extension_scripts(urls),
        )
      end

      def html(body)
        [200, { "content-type" => "text/html;charset=utf-8" }, [body]]
      end

      def json(body)
        [200, { "content-type" => "application/json" }, [JSON.generate(body)]]
      end

      def not_found(urls)
        renderer = Renderer.new
        content = renderer.render("not_found")
        [
          404,
          { "content-type" => "text/html;charset=utf-8" },
          [
            renderer.render(
              "layout",
              content: content,
              urls: urls,
              extension_stylesheets: extension_stylesheets(urls),
              extension_scripts: extension_scripts(urls),
            ),
          ],
        ]
      end
    end
  end
end
