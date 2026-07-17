# frozen_string_literal: true

require "uri"
require_relative "swimlane/version"
require_relative "swimlane/get_events_from_streams"

module RubyEventStore
  module Browser
    # Browser extension comparing several streams side by side: their events
    # merged into one newest-first timeline table, one column per stream,
    # with infinite scroll.
    class Swimlane
      VIEWS_ROOT = File.expand_path("swimlane/views", __dir__)
      PUBLIC_ROOT = File.expand_path("swimlane/public", __dir__)

      def register_routes(router, context)
        router.add_route("GET", "/swimlane") do |params, urls|
          stream_names, sort = read_params(params)
          reader = GetEventsFromStreams.new(event_store: context.event_store, stream_names: stream_names, sort: sort)

          context.render(
            "swimlane",
            views_root: VIEWS_ROOT,
            urls: urls,
            swimlane: self,
            stream_names: stream_names,
            events: reader.events,
            sort: sort,
            more_url: (more_url(urls, stream_names, reader.next_cursor, sort) if reader.more?),
          )
        end

        router.add_route("GET", "/swimlane/more") do |params, urls|
          stream_names, sort = read_params(params)
          reader =
            GetEventsFromStreams.new(
              event_store: context.event_store,
              stream_names: stream_names,
              cursor: params["cursor"],
              sort: sort,
            )

          context.json(
            html:
              context.render_partial(
                "_rows",
                views_root: VIEWS_ROOT,
                urls: urls,
                stream_names: stream_names,
                events: reader.events,
                sort: sort,
              ),
            more_url: (more_url(urls, stream_names, reader.next_cursor, sort) if reader.more?),
          )
        end

        router.add_route("GET", "/swimlane/swimlane.js") do |_, _|
          [200, { "content-type" => "text/javascript" }, [File.read(File.join(PUBLIC_ROOT, "swimlane.js"))]]
        end
      end

      def scripts(urls)
        ["#{urls.app_url}/swimlane/swimlane.js"]
      end

      def stream_links(stream_name, urls)
        [{ label: "Streamline", url: swimlane_url(urls, [stream_name]) }]
      end

      def swimlane_url(urls, stream_names, sort = nil)
        "#{urls.app_url}/swimlane?#{query(stream_names, sort)}"
      end

      def more_url(urls, stream_names, cursor, sort)
        query = query(stream_names, sort, [["cursor", cursor]])
        "#{urls.app_url}/swimlane/more?#{query}"
      end

      private

      def read_params(params)
        stream_names = Array(params["streams"]).reject { |name| name.nil? || name.empty? }.uniq
        sort = ("as_of" if params["sort"] == "as_of")
        [stream_names, sort]
      end

      def query(stream_names, sort, extra = [])
        pairs = stream_names.map { |name| ["streams[]", name] }
        pairs.concat(extra)
        pairs << ["sort", sort] if sort
        URI.encode_www_form(pairs)
      end
    end
  end
end
