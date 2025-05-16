# frozen_string_literal: true

require "ruby_event_store/active_record"
require "active_record"
load "ruby_event_store/active_record/tasks/migration_tasks.rake"

include ActiveRecord::Tasks

db_dir = ENV["DATABASE_DIR"] || "./db"

task :environment do
  connection = ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])
  DatabaseTasks.env = connection.db_config.env_name
  DatabaseTasks.db_dir = db_dir
  DatabaseTasks.migrations_paths = ENV["MIGRATIONS_PATH"] || File.join(db_dir, "migrate")
end

load "active_record/railties/databases.rake"
