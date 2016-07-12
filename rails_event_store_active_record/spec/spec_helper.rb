if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rails_event_store_active_record'

RSpec.configure do |config|
  config.around(:each) do |example|
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Schema.define do
      self.verbose = false
      create_table(:event_store_events) do |t|
        t.string      :stream,      null: false
        t.string      :event_type,  null: false
        t.string      :event_id,    null: false
        t.text        :metadata
        t.text        :data,        null: false
        t.datetime    :created_at,  null: false
      end
      add_index :event_store_events, :stream
      add_index :event_store_events, :created_at
      add_index :event_store_events, :event_type
      add_index :event_store_events, :event_id, unique: true
    end
    example.run
  end
end
