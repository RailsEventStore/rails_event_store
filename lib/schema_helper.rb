require_relative 'migrator'

module SchemaHelper
  def run_migration(name)
    m = Migrator.new(File.expand_path('../rails_event_store_active_record/lib/rails_event_store_active_record/generators/templates', __dir__))
    m.run_migration(name)
  end

  def establish_database_connection
    ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
  end

  def load_database_schema
    run_migration('create_event_store_events')
  end

  def drop_database
    ActiveRecord::Migration.drop_table("event_store_events")
    ActiveRecord::Migration.drop_table("event_store_events_in_streams")
  end

  def load_legacy_database_schema
    ActiveRecord::Schema.define do
      create_table(:event_store_events, force: false) do |t|
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
  end

  def drop_legacy_database
    ActiveRecord::Migration.drop_table("event_store_events")
  end
end
