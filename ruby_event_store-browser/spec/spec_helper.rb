require "ruby_event_store"
require "ruby_event_store/browser/app"
require "rack/test"
require "support/rspec_defaults"
require "support/mutant_timeout"

ENV['RACK_ENV'] = 'test'
# ENV['DATABASE_URL'] ||= 'sqlite:db.sqlite3'

EVENT_STORE_BUILDER = -> do
  RubyEventStore::Client.new(
    repository: RubyEventStore::InMemoryRepository.new
  )
end

EVENT_STORE = EVENT_STORE_BUILDER.call

APP_BUILDER = -> (event_store) do
  RubyEventStore::Browser::App.for(
    event_store_locator: -> { event_store },
    host: 'http://www.example.com'
  )
end

require "capybara/rspec"
require "selenium-webdriver"

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[headless disable-gpu no-sandbox]
  )
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
Capybara.javascript_driver = :chrome
# Capybara.app = APP_BUILDER.call(EVENT_STORE_BUILDER.call)

module SchemaHelper
  include Rack::Test::Methods

  def app
    APP_BUILDER.call(event_store)
  end

  def event_store
    @event_store ||= build_event_store
  end

  def build_event_store
    EVENT_STORE_BUILDER.call
  end

  def load_database_schema
    @event_store = nil
    Capybara.app = APP_BUILDER.call(event_store)
  end
end

RSpec.configure do |config|
  config.around(:each) do |example|
    unless example.metadata[:js]
      load_database_schema
    end

    example.call
  end
end
