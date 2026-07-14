# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require "rails/engine"
require "action_controller/railtie"

module RailsEventStore
  module HotwireBrowser
    class Engine < ::Rails::Engine
      isolate_namespace RailsEventStore::HotwireBrowser
    end
  end
end
