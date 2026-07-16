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

      def serializer
        RubyEventStore::Serializers::YAML
      end

      def run_lifecycle
        establish_database_connection
        load_database_schema
        load_outbox_schema
        reset_column_information
        yield
      ensure
        drop_database
      end

      def load_outbox_schema
        name = "add_published_at_to_event_store_events"
        outbox_migrator.run_migration(name, "#{outbox_template_directory}/#{name}")
      end

      def reset_column_information
        ::ActiveRecord::Base.reset_column_information
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

# ActiveJob needs a resolvable (non-anonymous) class name to enqueue/perform a job,
# so this lives at the top level rather than being built inline in specs.
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
