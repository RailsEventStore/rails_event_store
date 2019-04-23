# frozen_string_literal: true

module DresRails
  # Defines and registers the Rails engine.
  class Engine < ::Rails::Engine
    isolate_namespace DresRails
  end
end
