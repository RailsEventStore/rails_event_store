require 'ruby_event_store/browser/app'

module RailsEventStore
  module Browser
    class Engine
      def self.call(env)
        request = Rack::Request.new(env)
        app = RubyEventStore::Browser::App.for(
          event_store_locator: -> { Rails.configuration.event_store },
          host: request.base_url,
          path: request.script_name
        )
        app.call(env)
      end
    end
  end
end

