require 'rails_event_store'
require 'example_invoicing_app'
require 'support/fake_configuration'
require 'active_record'
require_relative '../../support/helpers/rspec_defaults'
require_relative '../../support/helpers/migrator'
require_relative '../../support/helpers/protobuf_helper'

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

module TimeEnrichment
  def with(event, timestamp: Time.now.utc, valid_at: nil)
    event.metadata[:timestamp] ||= timestamp
    event.metadata[:valid_at] ||= valid_at || timestamp
    event
  end
  module_function :with
end
