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

require "capybara/rspec"
require "selenium-webdriver"

Capybara.register_driver :chrome do |app|
  options =
    Selenium::WebDriver::Chrome::Options.new(
      args: %w[headless disable-gpu no-sandbox]
    )
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
Capybara.server = :webrick

DummyEvent = Class.new(::RubyEventStore::Event)
