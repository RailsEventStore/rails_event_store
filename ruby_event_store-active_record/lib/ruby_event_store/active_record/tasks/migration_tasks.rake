require_relative "../generators/migration_generator"

desc "Generate migration"
task "db:migrations:copy" do
  data_type = ENV["DATA_TYPE"] || raise("Specify data type (binary, json, jsonb): rake db:migrations:copy DATA_TYPE=json")

  path = RubyEventStore::ActiveRecord::MigrationGenerator
           .new
           .call(data_type, ENV["MIGRATION_PATH"] || "db/migrate")

  puts "Migration file created #{path}"
end