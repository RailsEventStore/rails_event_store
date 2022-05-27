# frozen_string_literal: true

begin
  require "rails/generators"
rescue LoadError
end

if defined?(Rails::Generators::Base)
  module RubyEventStore
    module Flipper
      class EventsGenerator < Rails::Generators::Base
        source_root File.expand_path(File.join(File.dirname(__FILE__), "./templates"))

        def create_migration
          template "events.rb", "app/models/ruby_event_store/flipper/events.rb"
        end
      end
    end
  end
end
