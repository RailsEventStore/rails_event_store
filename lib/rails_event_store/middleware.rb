module RailsEventStore
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      Thread.current[:rails_event_store] =
        { remote_ip: ActionDispatch::Request.new(env).remote_ip }
      @app.call(env)
    ensure
      Thread.current[:rails_event_store] = nil
      body.close if body && body.respond_to?(:close) && $!
    end
  end
end
