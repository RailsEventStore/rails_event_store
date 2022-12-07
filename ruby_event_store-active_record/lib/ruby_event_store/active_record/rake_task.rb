# frozen_string_literal: true

require "ruby_event_store/active_record"
require "active_record"
load "ruby_event_store/active_record/tasks/migration_tasks.rake"

include ActiveRecord::Tasks

db_dir = ENV["DATABASE_DIR"] || './db'

DatabaseTasks.env = ENV['ENV'] || 'development'
DatabaseTasks.db_dir = db_dir
DatabaseTasks.database_configuration = ENV['DATABASE_CONFIG'] || YAML.load(File.read('./config/database.yml'), aliases: true)

DatabaseTasks.migrations_paths = ENV["MIGRATIONS_PATH"] || File.join(db_dir, 'migrate')

task :environment do
  ActiveRecord::Base.configurations = DatabaseTasks.database_configuration
  ActiveRecord::Base.establish_connection DatabaseTasks.env
end

load 'active_record/railties/databases.rake'