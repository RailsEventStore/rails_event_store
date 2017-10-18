$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rails_event_store'
require 'example_invoicing_app'

MigrationCode = File.read( File.expand_path('../../../rails_event_store_active_record/lib/rails_event_store_active_record/generators/templates/migration_template.rb', __FILE__) )
MigrationCode.gsub!("<%= migration_version %>", "[4.2]")

RSpec.configure do |config|
  config.disable_monkey_patching!
  
  config.around(:each) do |example|
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Schema.define do
      self.verbose = false
      eval(MigrationCode) unless defined?(CreateEventStoreEvents)
      CreateEventStoreEvents.new.change
    end
    example.run
  end
end