# frozen_string_literal: true

require "ruby_event_store"
require "ruby_event_store/browser/app"
require "rack/test"
require "support/web_client"
require "support/api_client"
require "support/csp_app"
require "support/integration_helpers"
require_relative "../../support/helpers/rspec_defaults"
require_relative "../../support/helpers/time_enrichment"

ENV["RACK_ENV"] = "test"

begin
  require "rackup"
  $LOADED_FEATURES << "rack/handler/webrick.rb"
rescue LoadError
end

require "capybara/cuprite"
Capybara.server = :webrick
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    process_timeout: 30,
    browser_options: {
      "no-sandbox" => nil
    }
  )
end

DummyEvent = Class.new(::RubyEventStore::Event)
