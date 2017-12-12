require 'rails'

module RailsEventStore
  module Browser
    class Engine < ::Rails::Engine
      isolate_namespace RailsEventStore::Browser
    end
  end
end
