require "bundler/setup"
require "rails_event_store"
require "rails_event_store/browser"

ENV['RAILS_ENV'] ||= 'test'

require File.expand_path("../dummy/config/environment.rb", __FILE__)
MigrationCode = File.read(File.expand_path('../../../rails_event_store_active_record/lib/rails_event_store_active_record/generators/templates/migration_template.rb', __FILE__) )
migration_version = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("5.0.0") ? "" : "[4.2]"
MigrationCode.gsub!("<%= migration_version %>", migration_version)
MigrationCode.gsub!("force: false", "force: true")

require "rspec/rails"

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
  config.example_status_persistence_file_path = ".rspec_status"

  config.disable_monkey_patching!

  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.use_transactional_fixtures = true
end
