require_relative '../browser'
require 'sinatra/base'
require 'rack'

module RubyEventStore
  module Browser
    class App < Sinatra::Application # Sinatra::Base

      def self.for(event_store_locator:, host:, path: nil)
        self.tap do |app|
          app.settings.instance_exec do
            set :event_store_locator, event_store_locator
            set :host, host
            set :root_path, path
          end
        end
      end

      configure do
        set :host, nil
        set :root_path, nil
        set :event_store_locator, -> {}
        set :protection, except: :path_traversal
        set :public_folder, "#{__dir__}/../../../public"

        mime_type :json, 'application/vnd.api+json'
      end
      
      get '/' do
        erb %{
          <!DOCTYPE html>
          <html>
            <head>
              <title>RubyEventStore::Browser</title>
            </head>
            <body>
              <script type="text/javascript" src="<%= settings.root_path %>/ruby_event_store_browser.js"></script>
              <script type="text/javascript">
                RubyEventStore.Browser.Main.fullscreen({
                  rootUrl:    "<%= settings.root_path %>",
                  eventsUrl:  "<%= settings.root_path %>/events",
                  streamsUrl: "<%= settings.root_path %>/streams",
                  resVersion: "<%= RubyEventStore::VERSION %>"
                });
              </script>
            </body>
          </html>
        }
      end

      get '/events/:id' do
        event = Event.new(
          event_store: settings.event_store_locator,
          params: symbolized_params
        )

        content_type :json
        JSON.dump event.as_json
      end

      get '/streams/:id(/:position/:direction/:count)?' do
        stream = Stream.new(
          event_store: settings.event_store_locator,
          params: symbolized_params,
          url_builder: method(:streams_url_for)
        )
        
        content_type :json
        JSON.dump stream.as_json
      end

      helpers do
        def symbolized_params
          params.each_with_object({}) { |(k, v), h| v.nil? ? next : h[k.to_sym] = v }
        end

        def streams_url_for(options)
          base = [ settings.host, settings.root_path ].compact.join
          args = options.values_at(:id, :position, :direction, :count).compact
          args.map! { |a| Rack::Utils.escape(a) }

          "#{base}/streams/#{args.join('/')}"
        end
      end

    end
  end
end
