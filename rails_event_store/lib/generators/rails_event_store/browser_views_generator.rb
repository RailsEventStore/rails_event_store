# frozen_string_literal: true

require "rails/generators"
require "ruby_event_store/browser"

module RailsEventStore
  module Generators
    class BrowserViewsGenerator < Rails::Generators::Base
      source_root RubyEventStore::Browser::Renderer::VIEWS_ROOT

      def copy_views
        directory ".", "app/views/ruby_event_store_browser"
      end

      def instructions
        say "Browser picks these views up automatically. Delete the files you do not customize - " \
              "anything missing falls back to the views built into the gem."
      end
    end
  end
end
