module RailsEventStore
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      if @app.config.respond_to?(:event_store)
        @app.config.event_store.with_metadata(request_metadata(env)) do
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

    def metadata_proc
      @app.config.x.rails_event_store.request_metadata if @app.config.x.rails_event_store.request_metadata.respond_to?(:call)
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
