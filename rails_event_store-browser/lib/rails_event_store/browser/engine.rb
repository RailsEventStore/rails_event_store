require 'rails'
require 'active_support/core_ext/string/filters'
require 'ruby_event_store/browser'

module RailsEventStore
  module Browser
    class Engine < ::Rails::Engine
      isolate_namespace RailsEventStore::Browser

      initializer "static assets" do |app|
        app.middleware.insert_before(::ActionDispatch::Static, ::ActionDispatch::Static, "#{root}/public")
      end
    end
  end
end

