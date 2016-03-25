if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rails_event_store'
require 'example_invoicing_app'
require 'webmock/rspec'

RSpec.configure do |config|
  config.around(:each) do |example|
    RailsEventStoreActiveRecord::Event.establish_connection(
      :adapter => "sqlite3",
      :database => "spec/test.sqlite3"
    )
    RailsEventStoreActiveRecord::Event.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end

WebMock.allow_net_connect!
