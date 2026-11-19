# frozen_string_literal: true

require "ruby_event_store/scavenger"

namespace :res do
  desc "Hide and remove stream entries due for removal. Dry run unless EXECUTE=1 (see res-scavenge --help)"
  task scavenge: (Rake::Task.task_defined?(:environment) ? [:environment] : []) do
    exit_code = RubyEventStore::Scavenger::CLI.new.run(RubyEventStore::Scavenger::CLI.argv_from_env(ENV))
    exit(exit_code) unless exit_code.zero?
  end

  namespace :scavenge do
    desc "Show the scavenger status"
    task status: (Rake::Task.task_defined?(:environment) ? [:environment] : []) do
      RubyEventStore::Scavenger::CLI.new.run(["status"])
    end

    desc "Generate the migration creating event_store_scavenger_state (MIGRATION_PATH, default db/migrate)"
    task :migration do
      path = RubyEventStore::Scavenger::MigrationGenerator.new.call(ENV.fetch("MIGRATION_PATH", "db/migrate"))
      puts "Migration file created #{path}"
    end
  end
end
