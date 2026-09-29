# frozen_string_literal: true

require "spec_helper"
require_relative "../../../support/helpers/subprocess_helper"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe "Railtie", mutant: false do
      include SubprocessHelper

      it { run_in_subprocess(<<~'EOF') }
        # Isolate from the parent test process's own env: DATABASE_URL would
        # otherwise override config/database.yml below and point this at the
        # real, shared test database instead of an isolated in-memory sqlite.
        ENV.delete("DATABASE_URL")
        ENV.delete("DATA_TYPE")
        ENV["RAILS_ENV"] = "test"
        require "rails"
        require "active_record/railtie"
        require "ruby_event_store/outbox_relay"
        require "tmpdir"
        require "yaml"

        Dir.mktmpdir do |app_root|
          Dir.mkdir(File.join(app_root, "config"))
          File.write(
            File.join(app_root, "config", "database.yml"),
            { "test" => { "adapter" => "sqlite3", "database" => ":memory:" } }.to_yaml,
          )
          migration_dir = Dir.mktmpdir

          Class.new(Rails::Application) do
            config.root = app_root
            config.eager_load = false
            config.consider_all_requests_local = true
            config.secret_key_base = "i_am_a_secret"
          end.initialize!

          ::ActiveRecord::Base.connection.execute("CREATE TABLE event_store_events (id INTEGER PRIMARY KEY)")

          Rails.application.load_tasks

          raise "task not registered by the Railtie" unless
            Rake::Task.task_defined?("ruby_event_store:outbox_relay:install_migration")

          ENV["MIGRATION_PATH"] = migration_dir
          # No DATABASE_URL set: :environment must establish the app's own
          # connection (from config/database.yml above) before the task body
          # runs, rather than raising ActiveRecord::ConnectionNotEstablished.
          Rake::Task["ruby_event_store:outbox_relay:install_migration"].invoke

          raise "no migration file was generated" if Dir.children(migration_dir).empty?

          raise "requiring the gem changed RailsEventStore::Client" if defined?(RailsEventStore::Client) && RailsEventStore::Client.method_defined?(:subscribe_async)
          require "ruby_event_store/outbox_relay/rails"
          client = RubyEventStore::OutboxRelay::RailsClient.new
          raise "RailsClient can't subscribe_async" unless client.respond_to?(:subscribe_async)
          raise "RailsEventStore::Client was changed" if RailsEventStore::Client.method_defined?(:subscribe_async)
        end
      EOF
    end
  end
end
