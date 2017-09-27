$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rails_event_store'
require 'example_invoicing_app'

RSpec.configure do |config|
  config.disable_monkey_patching!
  
  config.around(:each) do |example|
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Schema.define do
      self.verbose = false

      create_table(:event_store_events_in_streams, force: true) do |t|
        t.string      :stream,      null: false
        t.integer     :position,    null: true
        t.references :event, null: false, type: :string
        t.datetime    :created_at,  null: false
      end
      add_index :event_store_events_in_streams, [:stream, :position], unique: true
      add_index :event_store_events_in_streams, [:created_at]
      add_index :event_store_events_in_streams, [:stream, :event_id], unique: true
      # add_index :event_store_events_in_streams, [:event_uuid]

      create_table(:event_store_events, id: false, force: true) do |t|
        t.string :id, limit: 36, primary_key: true, null: false
        t.string      :event_type,  null: false
        t.text        :metadata
        t.text        :data,        null: false
        t.datetime    :created_at,  null: false
      end
      add_index :event_store_events, :created_at

    end
    example.run
  end
end
