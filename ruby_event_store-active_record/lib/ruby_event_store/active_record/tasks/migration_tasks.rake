require_relative "../generators/migration_generator"

desc "Generate migration"
task "db:migrations:copy" do
  task = MigrationTask.new("db:migrations:copy")
  task.establish_connection

  path =
    RubyEventStore::ActiveRecord::MigrationGenerator.new.call(task.adapter, task.migration_path)

  puts "Migration file created #{path}"
end

desc "Generate migration for missing event_id index"
task "db:migrations:fix_missing_event_id_index" do
  task = MigrationTask.new("db:migrations:fix_missing_event_id_index")
  task.establish_connection

  path = RubyEventStore::ActiveRecord::EventIdIndexMigrationGenerator.new.call(task.migration_path)

  puts "Migration file created #{path}"
end

desc "Generate migration for adding foreign key on event_store_events_in_streams.event_id"
task "db:migrations:add_foreign_key_on_event_id" do
  task = MigrationTask.new("db:migrations:add_foreign_key_on_event_id")
  task.establish_connection

  path =
    RubyEventStore::ActiveRecord::ForeignKeyOnEventIdMigrationGenerator.new.call(task.adapter, task.migration_path)

  puts "Migration file created #{path}"
end

class MigrationTask
  def initialize(
    task,
    database_url: ENV["DATABASE_URL"],
    data_type: ENV["DATA_TYPE"],
    migration_path: ENV["MIGRATION_PATH"]
  )
    @task = task
    @data_type = data_type
    @migration_path = migration_path
    @database_url = database_url
  end

  def establish_connection
    ::ActiveRecord::Base.establish_connection(@database_url)
  end

  def adapter
    data_type = @data_type || raise("Specify data type (binary, json, jsonb): rake #{@task} DATA_TYPE=json")

    RubyEventStore::ActiveRecord::DatabaseAdapter.from_string(::ActiveRecord::Base.connection.adapter_name, data_type)
  end

  def migration_path
    @migration_path || "db/migrate"
  end
end