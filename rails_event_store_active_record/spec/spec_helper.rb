require 'rails_event_store_active_record'

ENV['DATABASE_URL']  ||= 'sqlite3:db.sqlite3'
ENV['RAILS_VERSION'] ||= '5.1.4'

MigrationCode = File.read(File.expand_path('../../lib/rails_event_store_active_record/generators/templates/migration_template.rb', __FILE__) )
migration_version = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("5.0.0") ? "" : "[4.2]"
MigrationCode.gsub!("<%= migration_version %>", migration_version)
MigrationCode.gsub!("force: false", "force: true")

module SchemaHelper
  def establish_database_connection
    ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
  end

  def load_database_schema
    ActiveRecord::Schema.define do
      self.verbose = false
      eval(MigrationCode) unless defined?(CreateEventStoreEvents)
      CreateEventStoreEvents.new.change
    end
  end

  def load_legacy_database_schema
    ActiveRecord::Schema.define do
      self.verbose = false
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
  rescue ActiveRecord::StatementInvalid
  end

  def drop_database
    ActiveRecord::Migration.drop_table("event_store_events")
    ActiveRecord::Migration.drop_table("event_store_events_in_streams")
  end
end

RSpec.configure do |config|
  config.failure_color = :magenta
end
