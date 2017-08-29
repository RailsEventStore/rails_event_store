if ENV['CODECLIMATE_REPO_TOKEN']
  require 'simplecov'
  SimpleCov.start
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rails_event_store_active_record'

ENV['DATABASE_URL'] ||= "postgres://localhost/rails_event_store_active_record?pool=5"

RSpec.configure do |config|
  config.failure_color = :magenta
  config.around(:each) do |example|
    ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
    ActiveRecord::Schema.define do
      self.verbose = false

      enable_extension "plpgsql"
      enable_extension "pgcrypto"

      create_table(:event_store_events_in_streams, force: true) do |t|
        t.string      :stream,      null: false
        t.integer     :position,    null: true
        if ENV['DATABASE_URL'].start_with?("postgres")
          t.references :event, null: false, type: :uuid
        else
          t.references :event, null: false, type: :string
        end
        t.datetime    :created_at,  null: false
      end
      add_index :event_store_events_in_streams, [:stream, :position], unique: true
      add_index :event_store_events_in_streams, [:created_at]
      # add_index :event_store_events_in_streams, [:stream, :event_uuid], unique: true
      # add_index :event_store_events_in_streams, [:event_uuid]

      if ENV['DATABASE_URL'].start_with?("postgres")
        create_table(:event_store_events, id: :uuid, force: true) do |t|
          t.string      :event_type,  null: false
          t.text        :metadata
          t.text        :data,        null: false
          t.datetime    :created_at,  null: false
        end
      else
        create_table(:event_store_events, id: false, force: true) do |t|
          t.string :id, limit: 36, primary_key: true, null: false
          t.string      :event_type,  null: false
          t.text        :metadata
          t.text        :data,        null: false
          t.datetime    :created_at,  null: false
        end
      end
      add_index :event_store_events, :created_at
    end
    example.run
  end
end
