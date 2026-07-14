# frozen_string_literal: true

require "ruby_event_store"
require "rails_event_store/hotwire_browser"
require "rack/test"
require "support/web_client"
require "support/csp_app"
require "support/integration_helpers"
require "support/test_application"
require_relative "../../../support/helpers/rspec_defaults"
require_relative "../../../support/helpers/time_enrichment"

ENV["RACK_ENV"] = "test"

require "capybara/cuprite"
Capybara.server = :webrick
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, process_timeout: 30, browser_options: { "no-sandbox" => nil })
end

DummyEvent = Class.new(::RubyEventStore::Event)
