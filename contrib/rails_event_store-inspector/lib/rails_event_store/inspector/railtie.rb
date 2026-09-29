# frozen_string_literal: true

require "rails/railtie"
require "active_support/notifications"
require_relative "insertion"
require_relative "middleware"
require_relative "collector"

module RailsEventStore
  module Inspector
    class Railtie < ::Rails::Railtie
      railtie_name "rails_event_store_inspector"

      initializer "rails_event_store_inspector.middleware", after: :load_config_initializers do |app|
        Insertion.call(app.middleware, ::RailsEventStore::Inspector::Middleware) if Inspector.install?
      end

      initializer "rails_event_store_inspector.collector", after: :load_config_initializers do
        Collector.new(Inspector.buffer, ActiveSupport::Notifications).subscribe if Inspector.install?
      end

      config.to_prepare { Inspector.reset_browser_links! }
    end
  end
end
