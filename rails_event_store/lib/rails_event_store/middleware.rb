module RailsEventStore
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      if config.respond_to?(:event_store)
        config.event_store.with_metadata(request_metadata(env)) do
          @app.call(env)
        end
      else
        @app.call(env)
      end
    end

    def request_metadata(env)
      (metadata_proc || default_request_metadata).call(env)
    end

    private
    
    def config
      Rails.application.config
    end

    def metadata_proc
      config.x.rails_event_store.request_metadata if config.x.rails_event_store.request_metadata.respond_to?(:call)
    end

    def default_request_metadata
      ->(env) do
        request = ActionDispatch::Request.new(env)
        {
          remote_ip:  request.remote_ip,
          request_id: request.uuid
        }
      end
    end
  end
end
