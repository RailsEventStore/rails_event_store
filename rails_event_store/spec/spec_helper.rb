require 'rails_event_store'
require 'example_invoicing_app'
require 'support/rspec_defaults'
require 'support/mutant_timeout'
require 'support/fake_configuration'
require 'pry'

MigrationCode = File.read( File.expand_path('../../../rails_event_store_active_record/lib/rails_event_store_active_record/generators/templates/migration_template.rb', __FILE__) )
migration_version = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("5.0.0") ? "" : "[4.2]"
MigrationCode.gsub!("<%= migration_version %>", migration_version)

RSpec.configure do |config|
  config.around(:each) do |example|
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Schema.define do
      self.verbose = $verbose
      eval(MigrationCode) unless defined?(CreateEventStoreEvents)
      CreateEventStoreEvents.new.change
    end
    example.run
  end

  config.around(:each) do |example|
    ActiveJob::Base.queue_adapter = :inline
    example.run
  end
end

$verbose = ENV.has_key?('VERBOSE') ? true : false
ActiveJob::Base.logger = nil unless $verbose