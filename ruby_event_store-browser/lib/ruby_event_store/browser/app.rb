# frozen_string_literal: true

require_relative '../browser'
require 'sinatra/base'

module RubyEventStore
  module Browser
    class App < Sinatra::Base
      def self.for(event_store_locator:, host: nil, path: nil, api_url: nil, environment: :production, related_streams_query: DEFAULT_RELATED_STREAMS_QUERY)
        self.tap do |app|
          app.settings.instance_exec do
            set :event_store_locator, event_store_locator
            set :related_streams_query, -> { related_streams_query }
            set :host, host
            set :root_path, path
            set :api_url, api_url
            set :environment, environment
            set :public_folder, "#{__dir__}/../../../public"
          end
        end
      end

      configure do
        set :host, nil
        set :root_path, nil
        set :api_url, nil
        set :event_store_locator, -> {}
        set :related_streams_query, nil
        set :protection, except: :path_traversal

        mime_type :json, 'application/vnd.api+json'
      end

      get '/api/events/:id' do
        begin
          json Event.new(
            event_store: settings.event_store_locator,
            params: symbolized_params,
          )
        rescue RubyEventStore::EventNotFound
          404
        end
      end

      get '/api/streams/:id' do
        json GetStream.new(
          stream_name: params[:id],
          routing: routing,
          related_streams_query: settings.related_streams_query,
        )
      end

      get '/api/streams/:id/relationships/events' do
        json GetEventsFromStream.new(
          event_store: settings.event_store_locator,
          params: symbolized_params,
          routing: routing,
        )
      end

      get %r{/(events/.*|streams/.*)?} do
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
                    rootUrl:    "<%= routing.root_url %>",
                    apiUrl:     "<%= api_url %>",
                    resVersion: "<%= RubyEventStore::VERSION %>"
                  }
                });
              </script>
            </body>
          </html>
        }, locals: { path: settings.root_path || request.script_name, api_url: settings.api_url || routing.api_url }
      end

      helpers do
        def symbolized_params
          params.each_with_object({}) { |(k, v), h| v.nil? ? next : h[k.to_sym] = v }
        end

        def routing
          Routing.new(
            settings.host || request.base_url,
            settings.root_path || request.script_name
          )
        end

        def json(data)
          content_type :json
          JSON.dump data.as_json
        end
      end
    end
  end
end
