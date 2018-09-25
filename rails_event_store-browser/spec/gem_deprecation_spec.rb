require "spec_helper"

module RailsEventStore
  RSpec.describe Browser, type: :request do
    include SchemaHelper

    before { load_database_schema }

    specify do
      deprecation_warning = <<~MSG
        RailsEventStore::Browser::Engine has been deprecated.

        This gem will be discontinued on next RailsEventStore release. 
        Please use 'ruby_event_store-browser' gem from now on.

        In Gemfile:
        
           gem 'ruby_event_store-browser', require: 'ruby_event_store/sbrowser/app'


        In routes.rb:
        
          mount RubyEventStore::Browser::App.for(
            event_store_locator: -> { Rails.configuration.event_store },
            host: 'http://localhost:3000',
            path: '/res'
          ) => '/res' if Rails.env.development?
      MSG

      expect { get("/res") }.to output(deprecation_warning).to_stderr
    end
  end
end
