require_relative "../generators/migration_generator"

desc "Generate migration"
task "db:migrations:copy" do
  data_type =
    ENV["DATA_TYPE"] || raise("Specify data type (binary, json, jsonb): rake db:migrations:copy DATA_TYPE=json")
  ::ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])
  database_adapter = ::ActiveRecord::Base.connection.adapter_name

  path =
    RubyEventStore::ActiveRecord::MigrationGenerator.new.call(
      data_type,
      database_adapter,
      ENV["MIGRATION_PATH"] || "db/migrate"
    )

  puts "Migration file created #{path}"
end

desc "Generate migration for missing event_id index"
task "db:migrations:fix_missing_event_id_index" do
  ::ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])

  path = RubyEventStore::ActiveRecord::EventIdIndexMigrationGenerator.new.call(ENV["MIGRATION_PATH"] || "db/migrate")

  puts "Migration file created #{path}"
end

desc "Generate migration for adding foreign key on event_store_events_in_streams.event_id"
task "db:migrations:add_foreign_key_on_event_id" do
  ::ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])

  path = RubyEventStore::ActiveRecord::ForeignKeyOnEventIdMigrationGenerator.new.call(ENV["MIGRATION_PATH"] || "db/migrate")

  puts "Migration file created #{path}"
end
