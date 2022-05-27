# frozen_string_literal: true

require "rails/railtie"
require_relative "middleware"

module RailsEventStore
  class Railtie < ::Rails::Railtie
    initializer "rails_event_store.middleware" do |rails|
      rails.middleware.use(::RailsEventStore::Middleware)
    end
  end
end
