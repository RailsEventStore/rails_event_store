require 'rails_event_store'
require 'example_invoicing_app'
require 'support/fake_configuration'
require_relative '../../lib/rspec_defaults'
require_relative '../../lib/mutant_timeout'
require_relative '../../lib/migrator'
require_relative '../../lib/protobuf_helper'
require 'pry'

RSpec.configure do |config|
  config.around(:each) do |example|
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    m = Migrator.new(File.expand_path('../../rails_event_store_active_record/lib/rails_event_store_active_record/generators/templates', __dir__))
    m.run_migration('create_event_store_events')
    example.run
  end

  config.around(:each) do |example|
    ActiveJob::Base.queue_adapter = :inline
    example.run
  end
end

$verbose = ENV.has_key?('VERBOSE') ? true : false
ActiveJob::Base.logger = nil unless $verbose
ActiveRecord::Schema.verbose = $verbose

DummyEvent = Class.new(RailsEventStore::Event)
