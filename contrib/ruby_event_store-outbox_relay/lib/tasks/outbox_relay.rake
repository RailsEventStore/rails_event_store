# frozen_string_literal: true

require_relative "../ruby_event_store/outbox_relay/generators/migration_generator"

desc "Generate migration adding published_at to event_store_events"
task "outbox_relay:install_migration" do
  path = RubyEventStore::OutboxRelay::MigrationGenerator.new.call(ENV["MIGRATION_PATH"] || "db/migrate")
  puts "Migration file created #{path}"
end

desc "Run the outbox relay (independent, long-running process; see --help for options)"
task "outbox_relay:run" do
  require_relative "../ruby_event_store/outbox_relay/cli"
  RubyEventStore::OutboxRelay::CLI.new.run(ENV["OUTBOX_RELAY_ARGS"].to_s.split)
end
