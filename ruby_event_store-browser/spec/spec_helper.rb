require "ruby_event_store"
require "ruby_event_store/browser/app"
require "support/test_client"
require_relative '../../lib/rspec_defaults'
require_relative '../../lib/mutant_timeout'

ENV['RACK_ENV'] = 'test'

require "capybara/rspec"
require "selenium-webdriver"

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[headless disable-gpu no-sandbox]
  )
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
Capybara.javascript_driver = :chrome

DummyEvent = Class.new(::RubyEventStore::Event)
