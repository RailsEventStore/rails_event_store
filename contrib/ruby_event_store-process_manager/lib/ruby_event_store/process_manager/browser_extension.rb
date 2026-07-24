# frozen_string_literal: true

require_relative "state_replay"

module RubyEventStore
  module ProcessManager
    class BrowserExtension
      VIEWS_ROOT = File.expand_path("views", __dir__).freeze
      STYLESHEET_PATH = File.expand_path("public/ruby_event_store_process_manager.css", __dir__).freeze

      def register_routes(router, context)
        context.serve_asset(router, "/process_manager_assets/stylesheet.css", STYLESHEET_PATH)

        router.add_route("GET", "/process_managers/:stream_name") do |params, urls|
          stream_name = params.fetch("stream_name")
          process_class, process_id = ProcessManager.parse_stream_name(stream_name)
          next [404, {}, []] unless process_class

          replay = StateReplay.new(event_store: context.event_store).call(process_class, stream_name)
          context.render(
            "process_managers/show",
            views_root: VIEWS_ROOT,
            urls: urls,
            stream_name: stream_name,
            process_class: process_class,
            process_id: process_id,
            steps: replay.steps,
            current_state: replay.current_state,
          )
        end
      end

      def stream_links(stream_name, urls)
        return [] unless ProcessManager.parse_stream_name(stream_name)

        [{ label: "Process state", url: urls.app_url_for("process_managers", stream_name) }]
      end

      def stylesheets(urls)
        [urls.app_url_for("process_manager_assets", "stylesheet.css")]
      end
    end
  end
end
