# frozen_string_literal: true

require "rails/railtie"
require_relative "middleware"
require_relative "implicit_dependencies"

module RailsEventStore
  class Railtie < ::Rails::Railtie
    initializer "rails_event_store.middleware" do |rails|
      rails.middleware.use(::RailsEventStore::Middleware)
    end

    config.after_initialize do
      if defined?(::Bundler::SharedHelpers) && ::Bundler::SharedHelpers.in_bundle?
        ImplicitDependencies.check(::Bundler.definition.dependencies.map(&:name))
      end
    end
  end
end
