require "bundler/setup"
require "ruby_event_store"
require "rails_event_store_active_record"
require "postgresql_queue"
require "concurrent"

# require 'rails'

ENV['DATABASE_URL']  ||= "postgres://localhost/rails_event_store_active_record?pool=5"
# ENV['RAILS_VERSION'] ||= Rails::VERSION::STRING

res_ar = Bundler.rubygems.all_specs.find{|a| a.name == "rails_event_store_active_record"}.full_gem_path
MigrationCode = File.read("#{res_ar}/lib/rails_event_store_active_record/generators/templates/migration_template.rb")
# migration_version = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("5.0.0") ? "" : "[4.2]"
migration_version = "[4.2]"
MigrationCode.gsub!("<%= migration_version %>", migration_version)
MigrationCode.gsub!("force: false", "force: true")

module SchemaHelper
  def establish_database_connection
    ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
  end

  def load_database_schema
    ActiveRecord::Schema.define do
      self.verbose = false
      eval(MigrationCode) unless defined?(CreateEventStoreEvents)
      CreateEventStoreEvents.new.change
    end
  end

  def drop_database
    ActiveRecord::Migration.drop_table("event_store_events")
    ActiveRecord::Migration.drop_table("event_store_events_in_streams")
  end
end

RSpec.configure do |config|
  config.failure_color = :magenta
end


RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end


end
