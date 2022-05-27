# frozen_string_literal: true

module RailsEventStore
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      if config.respond_to?(:event_store)
        config.event_store.with_request_metadata(env) { @app.call(env) }
      else
        @app.call(env)
      end
    end

    private

    def config
      Rails.application.config
    end
  end
end
