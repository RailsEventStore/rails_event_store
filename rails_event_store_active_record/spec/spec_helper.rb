if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rails_event_store_active_record'

RSpec.configure do |config|
  config.around(:each) do |example|
    RailsEventStoreActiveRecord::Event.establish_connection(
      :adapter => "sqlite3",
      :database => "spec/test.sqlite3",
      :timeout=> 10000
    )
    RailsEventStoreActiveRecord::Event.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
