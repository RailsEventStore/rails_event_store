# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require "rails/engine"
require "action_controller/railtie"

module RubyEventStore
  module Browser
    class Engine < ::Rails::Engine
      isolate_namespace RubyEventStore::Browser
    end
  end
end
