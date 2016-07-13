module RailsEventStore
  class Middleware
    def initialize(app, request_metadata_proc)
      @app = app
      @request_metadata_proc = request_metadata_proc
    end

    def call(env)
      Thread.current[:rails_event_store] = @request_metadata_proc.(env)
      @app.call(env)
    ensure
      Thread.current[:rails_event_store] = nil
    end
  end
end
