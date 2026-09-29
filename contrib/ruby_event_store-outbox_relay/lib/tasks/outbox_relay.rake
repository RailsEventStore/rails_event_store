# frozen_string_literal: true

require_relative "../ruby_event_store/outbox_relay/generators/migration_generator"

namespace :ruby_event_store do
  connect = -> { ::ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"]) if ENV["DATABASE_URL"] }
  dead_letters = lambda do
    require_relative "../ruby_event_store/outbox_relay"
    connect.call
    RubyEventStore::OutboxRelay::DeadLetters.new
  end

  desc "Generate migration creating the outbox tables"
  task "outbox_relay:install_migration" => :environment do
    connect.call
    database_adapter =
      RubyEventStore::ActiveRecord::DatabaseAdapter.from_string(::ActiveRecord::Base.connection.adapter_name)
    path =
      RubyEventStore::OutboxRelay::MigrationGenerator.new.call(database_adapter, ENV["MIGRATION_PATH"] || "db/migrate")
    puts "Migration file created #{path}"
  end

  desc "Run the outbox relay (independent, long-running process; see --help for options)"
  task "outbox_relay:run" do
    require_relative "../ruby_event_store/outbox_relay/cli"
    RubyEventStore::OutboxRelay::CLI.new.run(ENV["OUTBOX_RELAY_ARGS"].to_s.split)
  end

  desc "List outbox dead letters"
  task "outbox_relay:dead_letters:list" => :environment do
    dead_letters.call.each do |dead_letter|
      puts [
        dead_letter.id,
        dead_letter.event_id,
        dead_letter.topic,
        dead_letter.subscriber,
        dead_letter.attempts,
        dead_letter.error_class,
        dead_letter.dead_at.utc.iso8601,
      ].join("\t")
    end
  end

  desc "Move outbox dead letter(s) back to the outbox: ID, or all (optionally narrowed by TOPIC and SUBSCRIBER)"
  task "outbox_relay:dead_letters:retry", [:id] => :environment do |_task, args|
    if args.fetch(:id) == "all"
      count = dead_letters.call.requeue_all(topic: ENV["TOPIC"], subscriber: ENV["SUBSCRIBER"])
      puts "Requeued #{count} dead letter(s)"
    else
      dead_letters.call.requeue(Integer(args.fetch(:id)))
      puts "Requeued dead letter #{args.fetch(:id)}"
    end
  end

  desc "Delete an outbox dead letter permanently"
  task "outbox_relay:dead_letters:discard", [:id] => :environment do |_task, args|
    dead_letters.call.discard(Integer(args.fetch(:id)))
    puts "Discarded dead letter #{args.fetch(:id)}"
  end
end
