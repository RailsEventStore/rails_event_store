# frozen_string_literal: true

require_relative "../browser"
require "rack"
require "uri"

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
        warn(<<~WARN) if api_url
          Passing :api_url to RubyEventStore::Browser::App.for is deprecated.

          This option is no-op and will be removed in next major release.
        WARN

        Rack::Builder.new do
          use Rack::Static,
              urls:
                %w[
                  ruby_event_store_browser.js
                  stimulus.js
                  ruby_event_store_browser.css
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
              )
        end
      end

      def initialize(event_store_locator:, related_streams_query:, host:, root_path:)
        @event_store_locator = event_store_locator
        @related_streams_query = related_streams_query
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
               )
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

        router.handle(request)
      rescue EventNotFound
        not_found(routing.with_request(request))
      rescue Router::NoMatch
        [404, {}, []]
      end

      private

      attr_reader :event_store_locator, :related_streams_query, :routing

      def event_store
        event_store_locator.call
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
        renderer.render("layout", content: content, urls: urls)
      end

      def html(body)
        [200, { "content-type" => "text/html;charset=utf-8" }, [body]]
      end

      def not_found(urls)
        renderer = Renderer.new
        content = renderer.render("not_found")
        [404, { "content-type" => "text/html;charset=utf-8" },
         [renderer.render("layout", content: content, urls: urls)]]
      end
    end
  end
end
