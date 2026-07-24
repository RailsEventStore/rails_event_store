# frozen_string_literal: true

module RubyEventStore
  module Browser
    class ExtensionContext
      attr_reader :event_store

      def initialize(event_store, layout)
        @event_store = event_store
        @layout = layout
      end

      def render(template, urls:, title: nil, **locals)
        @layout.page(template, urls: urls, title: title, **locals)
      end

      def render_partial(template, urls:, **locals)
        @layout.partial(template, urls: urls, **locals)
      end

      def json(body)
        [200, { "content-type" => "application/json" }, [JSON.generate(body)]]
      end

      def serve_asset(router, route_path, file_path)
        router.add_route("GET", route_path) do |_, _|
          [200, { "content-type" => Rack::Mime.mime_type(File.extname(file_path)) }, [File.read(file_path)]]
        end
      end

      def not_found(urls, message: "Page not found")
        @layout.not_found(urls, message: message)
      end
    end
  end
end
