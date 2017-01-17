require 'rails/railtie'
require 'rails_event_store/middleware'

module RailsEventStore
  class Railtie < ::Rails::Railtie
    initializer 'rails_event_store.middleware' do |rails|
      rails.middleware.use(::RailsEventStore::Middleware, RailsConfig.new(rails.config).request_metadata)
    end

    class RailsConfig
      def initialize(config)
        @config = config
      end

      def request_metadata
        return default_request_metadata unless @config.respond_to?(:rails_event_store)
        @config.rails_event_store.fetch(:request_metadata, default_request_metadata)
      end

      private
      def default_request_metadata
        ->(env) do
          request = ActionDispatch::Request.new(env)
          { remote_ip:  request.remote_ip,
            request_id: request.uuid,
          }
        end
      end
    end
  end
end

