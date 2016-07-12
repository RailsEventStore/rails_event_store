module RailsEventStore
  class Middleware
    def initialize(app, request_metadata)
      @app = app
      @request_metadata = request_metadata
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      Thread.current[:rails_event_store] = @request_metadata.(env)
      @app.call(env)
    ensure
      Thread.current[:rails_event_store] = nil
    end
  end
end
