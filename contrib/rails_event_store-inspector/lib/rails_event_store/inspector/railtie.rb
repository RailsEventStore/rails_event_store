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

      initializer "rails_event_store_inspector.middleware" do |app|
        Insertion.call(app.middleware, ::RailsEventStore::Inspector::Middleware)
      end

      initializer "rails_event_store_inspector.collector" do
        Collector.new(Inspector.buffer, ActiveSupport::Notifications).subscribe
      end

      config.to_prepare { Inspector.reset_browser_links! }
    end
  end
end
