require 'ruby_event_store/browser/app'

module RailsEventStore
  module Browser
    class Engine
      def self.call(env)
        warn <<~EOW
          RailsEventStore::Browser::Engine has been deprecated.

          This gem will be discontinued on next RailsEventStore release. 
          Please use 'ruby_event_store-browser' gem from now on.

          In Gemfile:

             gem 'ruby_event_store-browser', require: 'ruby_event_store/sbrowser/app'


          In routes.rb:

            mount RubyEventStore::Browser::App.for(
              event_store_locator: -> { Rails.configuration.event_store },
              host: 'http://localhost:3000',
              path: '/res'
            ) => '/res' if Rails.env.development?
        EOW

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

