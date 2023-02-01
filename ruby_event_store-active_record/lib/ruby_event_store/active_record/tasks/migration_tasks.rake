require_relative "../generators/migration_generator"

desc "Generate migration"
task "db:migrations:copy" do
  data_type = ENV["DATA_TYPE"] || raise("Specify data type (binary, json, jsonb): rake db:migrations:copy DATA_TYPE=json")
  ::ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])
  database_adapter = ::ActiveRecord::Base.connection.adapter_name

  path = RubyEventStore::ActiveRecord::MigrationGenerator
           .new
           .call(data_type, database_adapter, ENV["MIGRATION_PATH"] || "db/migrate")

  puts "Migration file created #{path}"
end