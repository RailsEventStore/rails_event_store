require "rails_event_store"
require "rails_event_store/browser"
require "support/rspec_defaults"

ENV['RAILS_ENV']     ||= 'test'
ENV['RAILS_VERSION'] ||= '5.2.0.rc2'
ENV['DATABASE_URL']  ||= 'sqlite3:db.sqlite3'

dummy_app_name = "dummy_#{ENV['RAILS_VERSION'].gsub(".", "_")}"
require "#{File.join(__dir__, dummy_app_name)}/config/environment.rb"

MigrationCode = File.read(File.expand_path('../../../rails_event_store_active_record/lib/rails_event_store_active_record/generators/templates/migration_template.rb', __FILE__) )
migration_version = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("5.0.0") ? "" : "[4.2]"
MigrationCode.gsub!("<%= migration_version %>", migration_version)
MigrationCode.gsub!("force: false", "force: true")

require "rspec/rails"
require "capybara/rspec"
require "selenium-webdriver"

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[headless disable-gpu no-sandbox]
  )
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
Capybara.javascript_driver = :chrome

module SchemaHelper
  def load_database_schema
    ActiveRecord::Schema.define do
      self.verbose = false
      eval(MigrationCode) unless defined?(CreateEventStoreEvents)
      CreateEventStoreEvents.new.change
    end
  end
end

RSpec.configure do |config|
  config.before(:each) do |example|
    config.use_transactional_fixtures = !example.metadata[:js]
  end

  config.around(:each) do |example|
    Timeout.timeout(5, &example)
  end
end
