# frozen_string_literal: true

require "rack"
require_relative "state_replay"

module RubyEventStore
  module ProcessManager
    class BrowserExtension
      VIEWS_ROOT = File.expand_path("views", __dir__).freeze
      STYLESHEET_PATH = File.expand_path("public/ruby_event_store_process_manager.css", __dir__).freeze

      def register_routes(router, context)
        router.add_route("GET", "/process_manager_assets/stylesheet.css") do |_, _|
          [200, { "content-type" => "text/css" }, [File.read(STYLESHEET_PATH)]]
        end

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

        [{ label: "Process state", url: "#{urls.app_url}/process_managers/#{Rack::Utils.escape(stream_name)}" }]
      end

      def stylesheets(urls)
        ["#{urls.app_url}/process_manager_assets/stylesheet.css"]
      end
    end
  end
end
