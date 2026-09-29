# frozen_string_literal: true

require "ruby_event_store"
require "ruby_event_store/active_record"
require "ruby_event_store/outbox_relay"
require_relative "../../../support/helpers/rspec_defaults"
require_relative "../../../support/helpers/migrator"
require_relative "../../../support/helpers/schema_helper"

ENV["DATABASE_URL"] ||= "sqlite3::memory:"
ENV["DATA_TYPE"] ||= "binary"

$verbose = ENV.has_key?("VERBOSE") ? true : false
ActiveRecord::Schema.verbose = $verbose
ActiveJob::Base.queue_adapter = :inline
ActiveJob::Base.logger = Logger.new(File::NULL)

module RubyEventStore
  module OutboxRelay
    class SpecHelper
      include SchemaHelper

      # The serializer matching ENV["DATA_TYPE"]: YAML output isn't valid JSON,
      # so a json/jsonb column needs the JSON serializer instead.
      def serializer
        json_data_type? ? JSON : RubyEventStore::Serializers::YAML
      end

      def json_data_type?
        %w[json jsonb].include?(ENV["DATA_TYPE"])
      end

      def run_lifecycle
        establish_database_connection
        load_database_schema
        load_outbox_schema
        yield
      ensure
        drop_outbox_schema
        drop_database
      end

      def load_outbox_schema
        name = "create_event_store_outbox_tables"
        outbox_migrator.run_migration(name, "#{outbox_template_directory}/#{name}")
        [Message, DeadLetter].each(&:reset_column_information)
      end

      def drop_outbox_schema
        %w[event_store_outbox_messages event_store_outbox_dead_letters].each do |table|
          ::ActiveRecord::Migration.drop_table(table, if_exists: true)
        end
      end

      def repository
        RubyEventStore::ActiveRecord::EventRepository.new(serializer: serializer)
      end

      def postgres?
        ENV["DATABASE_URL"].include?("postgres")
      end

      def mysql?
        ENV["DATABASE_URL"].include?("mysql2")
      end

      # A throwaway subclass with the extension mixed in, so specs don't leave
      # RubyEventStore::Client itself permanently mutated between examples.
      def extended_client_class
        Class.new(RubyEventStore::Client)
      end

      def sync_subscriptions
        AsyncSubscriptions.new(dispatcher: RubyEventStore::SyncScheduler.new)
      end

      private

      def outbox_template_directory
        return "postgres" if postgres?
        return "mysql" if mysql?
        "sqlite"
      end

      def outbox_migrator
        Migrator.new(
          File.expand_path("../lib/ruby_event_store/outbox_relay/generators/templates", __dir__),
        )
      end
    end
  end
end

TestEvent = Class.new(RubyEventStore::Event)

module RecordingHandlers
  def recording_handler(name, &on_call)
    handler =
      Class.new do
        define_singleton_method(:received) { @received ||= [] }
        define_singleton_method(:call) do |event|
          on_call&.call(event)
          received << event
        end
      end
    stub_const(name, handler)
  end
end

RSpec.configure { |config| config.include RecordingHandlers }

# ActiveJob needs a resolvable (non-anonymous) class name to enqueue/perform a job,
# so this lives at the top level rather than being built inline in specs.
AnotherTestEvent = Class.new(RubyEventStore::Event)

module RecordingHandlers
  def recording_handler(name, &on_call)
    handler =
      Class.new do
        define_singleton_method(:received) { @received ||= [] }
        define_singleton_method(:call) do |event|
          on_call&.call(event)
          received << event
        end
      end
    stub_const(name, handler)
  end
end

RSpec.configure { |config| config.include RecordingHandlers }

class TestAsyncJob < ActiveJob::Base
  def self.received
    @received ||= []
  end

  def self.reset!
    @received = []
  end

  def perform(payload)
    self.class.received << payload
  end
end
