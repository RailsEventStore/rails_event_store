require "spec_helper"
require_relative "../../support/helpers/silence_stdout"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe MigrationGenerator do
      around { |example| SilenceStdout.silence_stdout { example.run } }
      around do |example|
        begin
          @dir = Dir.mktmpdir(nil, "./")
          example.call
        ensure
          FileUtils.rm_r(@dir)
          FileUtils.rm_f(["./20221130213700_create_event_store_events.rb"])
        end
      end

      before { allow(Time).to receive(:now).and_return(Time.new(2022, 11, 30, 21, 37, 00)) }

      specify "it is created within specified directory" do
        migration_generator(@dir)

        expect(migration_exists?(@dir)).to be_truthy
      end

      specify "returns path to migration file" do
        path = migration_generator(@dir)

        expected_path = "#{@dir}/20221130213700_create_event_store_events.rb"
        expect(path).to match(expected_path)
      end

      specify "uses particular migration version" do
        migration_generator(@dir)

        expect(read_migration(@dir)).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      specify "uses particular migration version for rails 6.0" do
        skip unless ENV["BUNDLE_GEMFILE"]&.include?("rails_6_0")

        migration_generator(@dir)

        expect(read_migration(@dir)).to include("ActiveRecord::Migration[6.0]")
      end

      specify "uses particular migration version for rails 6.1" do
        skip unless ENV["BUNDLE_GEMFILE"]&.include?("rails_6_1")

        migration_generator(@dir)

        expect(read_migration(@dir)).to include("ActiveRecord::Migration[6.1]")
      end

      specify "creates migration with binary data type for SQLite adapter" do
        migration_generator(@dir, "binary", "SQLite")

        expect(read_migration(@dir)).to match(/t.binary\s+:data/)
        expect(read_migration(@dir)).to match(/t.binary\s+:metadata/)
      end

      specify "throws on attempt to create migration with json data type for SQLite adapter" do
        expect {migration_generator(@dir, "json", "SQLite")}
          .to raise_error "sqlite doesn't support json"
      end

      specify "throws on attempt to create migration with jsonb data type for SQLite adapter" do
        expect { migration_generator(@dir, "jsonb", "SQLite") }
          .to raise_error("sqlite doesn't support jsonb")
      end

      specify "throws on attempt to create migration with jsonb data type for MySQL2 adapter" do
        expect { migration_generator(@dir, "jsonb", "MySQL2") }
          .to raise_error("MySQL2 doesn't support jsonb")
      end

      specify "creates migration with binary data type for MySQL2 adapter" do
        migration_generator(@dir, "binary", "MySQL2")

        expect(read_migration(@dir)).to match(/t.binary\s+:data/)
        expect(read_migration(@dir)).to match(/t.binary\s+:metadata/)
      end

      specify "creates migration with json data type for MySQL2 adapter" do
        migration_generator(@dir, "json", "MySQL2")

        expect(read_migration(@dir)).to match(/t.json\s+:data/)
        expect(read_migration(@dir)).to match(/t.json\s+:metadata/)
      end

      specify "creates migration with binary data type for PostgreSQL adapter" do
        migration_generator(@dir, "binary", "PostgreSQL")

        expect(read_migration(@dir)).to match(/t.binary\s+:data/)
        expect(read_migration(@dir)).to match(/t.binary\s+:metadata/)
      end

      specify "creates migration with json data type for PostgreSQL adapter" do
        migration_generator(@dir, "json", "PostgreSQL")

        expect(read_migration(@dir)).to match(/t.json\s+:data/)
        expect(read_migration(@dir)).to match(/t.json\s+:metadata/)
      end

      specify "creates migration with jsonb data type for PostgreSQL adapter" do
        migration_generator(@dir, "jsonb", "postgresql")

        expect(read_migration(@dir)).to match(/t.jsonb\s+:data/)
        expect(read_migration(@dir)).to match(/t.jsonb\s+:metadata/)
      end

      specify "raises error when data type is not supported" do
        expect { migration_generator(@dir, "invalid") }.to raise_error(
                                                             ArgumentError,
                                                             "Invalid value for data type. Supported for options are: binary, json, jsonb."
                                                           )
      end

      private

      def migration_generator(dir, data_type = "binary", database_adapter = "sqlite")
        ActiveRecord::MigrationGenerator.new.call(data_type, database_adapter, dir)
      end

      def migration_exists?(dir)
        File.exist?("#{dir}/20221130213700_create_event_store_events.rb")
      end

      def read_migration(dir)
        File.read("#{dir}/20221130213700_create_event_store_events.rb")
      end
    end
  end
end
