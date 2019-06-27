# frozen_string_literal: true

require_relative '../browser'
require 'sinatra'

module RubyEventStore
  module Browser
    class App < Sinatra::Application
      def self.for(event_store_locator:, host: nil, path: nil, environment: :production)
        self.tap do |app|
          app.settings.instance_exec do
            set :event_store_locator, event_store_locator
            set :host, host
            set :root_path, path
            set :environment, environment
            set :public_folder, "#{__dir__}/../../../public"
          end
        end
      end

      configure do
        set :host, nil
        set :root_path, nil
        set :event_store_locator, -> {}
        set :protection, except: :path_traversal

        mime_type :json, 'application/vnd.api+json'
      end

      get '/' do
        erb %{
          <!DOCTYPE html>
          <html>
            <head>
              <title>RubyEventStore::Browser</title>
              <link type="text/css" rel="stylesheet" href="<%= path %>/ruby_event_store_browser.css">
            </head>
            <body>
              <script type="text/javascript" src="<%= path %>/ruby_event_store_browser.js"></script>
              <script type="text/javascript">
                RubyEventStore.Browser.Elm.Main.init({
                  flags: {
                    rootUrl:    "<%= path %>",
                    eventsUrl:  "<%= path %>/events",
                    streamsUrl: "<%= path %>/streams",
                    resVersion: "<%= RubyEventStore::VERSION %>"
                  }
                });
              </script>
            </body>
          </html>
        }, locals: { path: settings.root_path || request.script_name }
      end

      get '/events/:id' do
        begin
          json Event.new(
            event_store: settings.event_store_locator,
            params: symbolized_params,
          )
        rescue RubyEventStore::EventNotFound
          404
        end
      end

      get '/streams/:id' do
        json Stream.new(
          event_store: settings.event_store_locator,
          params: symbolized_params,
          url_builder: method(:streams_url_for)
        )
      end

      get '/streams/:id/:position/:direction/:count' do
        json Stream.new(
          event_store: settings.event_store_locator,
          params: symbolized_params,
          url_builder: method(:streams_url_for)
        )
      end

      helpers do
        def symbolized_params
          params.each_with_object({}) { |(k, v), h| v.nil? ? next : h[k.to_sym] = v }
        end

        def streams_url_for(options)
          host = settings.host      || request.base_url
          path = settings.root_path || request.script_name
          base = [host, path].compact.join
          args = options.values_at(:id, :position, :direction, :count).compact
          args.map! { |a| Rack::Utils.escape(a) }

          "#{base}/streams/#{args.join('/')}"
        end

        def json(data)
          content_type :json
          JSON.dump data.as_json
        end
      end
    end
  end
end
