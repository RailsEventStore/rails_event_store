# frozen_string_literal: true

require "bundler/setup"
require "pry"
require "pry-byebug"

res_ar = Bundler.rubygems.all_specs.find{|a| a.name == "rails_event_store_active_record"}.full_gem_path
MigrationCode = File.read("#{res_ar}/lib/rails_event_store_active_record/generators/templates/migration_template.rb")
# migration_version = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("5.0.0") ? "" : "[4.2]"
migration_version = "[4.2]"
MigrationCode.gsub!("<%= migration_version %>", migration_version)
MigrationCode.gsub!("force: false", "force: true")

module SchemaHelper
  def establish_database_connection
    # ActiveRecord::Connection.clear_active_connections!
    # ActiveRecord::Connection.clear_all_connections!()
    ch = ActiveRecord::Base.connection_handler
    ch.connection_pools.each do | pool |
      pool.disconnect!
    end
    ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
  end

  def load_database_schema
    # ActiveRecord::Base.logger = Logger.new(STDOUT)
    # return
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
  config.color = true
  config.order = "random"
  config.formatter = ENV["CI"] == "true" ? :progress : :documentation
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "./tmp/rspec-status.txt"
  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  $stdout = File.new("/dev/null", "w") if ENV["SUPPRESS_STDOUT"] == "enabled"
  $stderr = File.new("/dev/null", "w") if ENV["SUPPRESS_STDERR"] == "enabled"
end
