require 'rails/generators' # doh
require 'rails_event_store_active_record'
require 'ruby_event_store'
require 'logger'

$verbose = ENV.has_key?('VERBOSE') ? true : false

ActiveRecord::Base.logger = Logger.new(STDOUT) if $verbose
ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'].gsub("db.sqlite3", "../../db.sqlite3"))
ActiveRecord::Schema.define do
  self.verbose = $verbose
  postgres = ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
  sqlite   = ActiveRecord::Base.connection.adapter_name == "SQLite"
  rails_42 = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("5.0.0")
  enable_extension "pgcrypto" if postgres
  create_table(:event_store_events_in_streams, force: false) do |t|
    t.string      :stream,      null: false
    t.integer     :position,    null: true
    if postgres
      t.references :event, null: false, type: :uuid, index: false
    else
      t.references :event, null: false, type: :string, index: false
    end
    t.datetime    :created_at,  null: false
  end
  add_index :event_store_events_in_streams, [:stream, :position], unique: true
  add_index :event_store_events_in_streams, [:created_at]
  add_index :event_store_events_in_streams, [:stream, :event_id], unique: true

  if postgres
    create_table(:event_store_events, id: :uuid, default: 'gen_random_uuid()', force: false) do |t|
      t.string      :event_type,  null: false
      t.text        :metadata
      t.text        :data,        null: false
      t.datetime    :created_at,  null: false
    end
  else
    create_table(:event_store_events, id: false, force: false) do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.string      :event_type,  null: false
      t.text        :metadata
      t.text        :data,        null: false
      t.datetime    :created_at,  null: false
    end
    if sqlite && rails_42
      add_index :event_store_events, :id, unique: true
    end
  end
  add_index :event_store_events, :created_at
end

puts "filled" if $verbose
