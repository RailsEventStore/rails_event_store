# frozen_string_literal: true

require "ruby_event_store/scavenger"
require "ruby_event_store/scavenger/job"
require_relative "../../../support/helpers/rspec_defaults"
require_relative "../../../support/helpers/rspec_sql_matchers"
require_relative "../../../support/helpers/schema_helper"

ENV["DATABASE_URL"] ||= "sqlite3::memory:"
ActiveRecord::Schema.verbose = false
ActiveJob::Base.logger = Logger.new(nil)

module RubyEventStore
  module Scavenger
    class SpecHelper
      include SchemaHelper

      SUPPORT_HELPERS = File.expand_path("../../../support/helpers", __dir__)
      AR_TEMPLATES =
        File.expand_path(
          "../../../ruby_event_store-active_record/lib/ruby_event_store/active_record/generators/templates",
          __dir__,
        )
      TEMPLATES = File.expand_path("../lib/ruby_event_store/scavenger/templates", __dir__)

      def run_lifecycle
        establish_database_connection
        load_database_schema
        ::ActiveRecord::Migration.suppress_messages do
          Migrator.new(File.expand_path(template_path, SUPPORT_HELPERS)).run_migration(
            "add_truncated_at_to_event_store_events_in_streams",
            connection: ::ActiveRecord::Base.connection,
          )
          Migrator.new(AR_TEMPLATES).run_migration("create_event_store_streams_metadata")
          Migrator.new(TEMPLATES).run_migration("create_event_store_scavenger_state")
        end
        ::ActiveRecord::Base.reset_column_information
        yield
      ensure
        ::ActiveRecord::Migration.suppress_messages do
          ::ActiveRecord::Migration.drop_table(State::TABLE, if_exists: true)
          ::ActiveRecord::Migration.drop_table("event_store_streams_metadata", if_exists: true)
        end
        drop_database
      end

      # The serializer that fits the data and metadata columns of DATA_TYPE.
      def self.serializer
        json? ? ::JSON : Serializers::YAML
      end

      # The same, as named on the command line.
      def self.serializer_name
        json? ? "json" : "yaml"
      end

      def self.json?
        ENV["DATA_TYPE"].to_s.start_with?("json")
      end

      def adapter
        ::ActiveRecord::Base.connection.adapter_name.downcase
      end

      def sqlite?
        adapter.eql?("sqlite")
      end
    end

    class CustomApplicationRecord < ::ActiveRecord::Base
      self.abstract_class = true
    end

    class FakeClock
      def initialize(time = Time.at(Time.now.to_i, 123_456_789, :nsec).utc)
        @time = time
      end

      def call
        @time
      end

      def advance(seconds)
        @time += seconds
      end

      def at(time)
        @time = time
      end
    end
  end
end

RSpec.configure do |config|
  helper = RubyEventStore::Scavenger::SpecHelper.new
  config.around(:each, :db) { |example| helper.run_lifecycle { example.run } }
  config.define_derived_metadata { |metadata| metadata[:db] = true unless metadata.key?(:db) }
end
