# frozen_string_literal: true

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
        end
      end

      before { allow(Time).to receive(:now).and_return(Time.new(2022, 11, 30, 21, 37, 00)) }

      specify "it is created within specified directory" do
        MigrationGenerator.new.call(DatabaseAdapter.from_string("sqlite", "binary"), @dir)
        expect(File.exist?("#{@dir}/20221130213700_create_event_store_events.rb")).to be true
      end

      specify "returns path to migration file" do
        path, _ = generate(@dir)
        expect(path).to eq("#{@dir}/20221130213700_create_event_store_events.rb")
      end

      specify "uses particular migration version" do
        _, content = generate(@dir)
        expect(content).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      specify "creates migration with binary data type for SQLite adapter" do
        _, content = generate(@dir, "binary", "SQLite")
        expect(content).to match(/t.binary\s+:data/)
        expect(content).to match(/t.binary\s+:metadata/)
      end

      specify "throws on attempt to create migration with json data type for SQLite adapter" do
        expect { generate(@dir, "json", "SQLite") }.to raise_error(
          InvalidDataTypeForAdapter,
          "SQLite doesn't support \"json\". Supported types are: binary.",
        )
      end

      specify "throws on attempt to create migration with jsonb data type for SQLite adapter" do
        expect { generate(@dir, "jsonb", "SQLite") }.to raise_error(
          InvalidDataTypeForAdapter,
          "SQLite doesn't support \"jsonb\". Supported types are: binary.",
        )
      end

      specify "throws on attempt to create migration with jsonb data type for MySQL adapter" do
        expect { generate(@dir, "jsonb", "MySQL2") }.to raise_error(
          InvalidDataTypeForAdapter,
          "MySQL doesn't support \"jsonb\". Supported types are: binary, json.",
        )
      end

      specify "creates migration with binary data type for MySQL adapter" do
        _, content = generate(@dir, "binary", "MySQL2")
        expect(content).to match(/t.binary\s+:data/)
        expect(content).to match(/t.binary\s+:metadata/)
      end

      specify "creates migration with json data type for MySQL2 adapter" do
        _, content = generate(@dir, "json", "MySQL2")
        expect(content).to match(/t.json\s+:data/)
        expect(content).to match(/t.json\s+:metadata/)
      end

      specify "creates migration with binary data type for PostgreSQL adapter" do
        _, content = generate(@dir, "binary", "PostgreSQL")
        expect(content).to match(/t.binary\s+:data/)
        expect(content).to match(/t.binary\s+:metadata/)
      end

      specify "creates migration with json data type for PostgreSQL adapter" do
        _, content = generate(@dir, "json", "PostgreSQL")
        expect(content).to match(/t.json\s+:data/)
        expect(content).to match(/t.json\s+:metadata/)
      end

      specify "creates migration with jsonb data type for PostgreSQL adapter" do
        _, content = generate(@dir, "jsonb", "postgresql")
        expect(content).to match(/t.jsonb\s+:data/)
        expect(content).to match(/t.jsonb\s+:metadata/)
      end

      specify "creates migration with COALESCE index for PostgreSQL adapter" do
        _, content = generate(@dir, "binary", "PostgreSQL")
        expect(content).to include(
          'add_index :event_store_events, "COALESCE(valid_at, created_at)", name: "index_event_store_events_on_as_of"',
        )
      end

      specify "does not create migration with COALESCE index for non-PostgreSQL adapter" do
        _, content = generate(@dir, "binary", "MySQL2")
        expect(content).not_to include("COALESCE")
      end

      specify "raises error when data type is not supported" do
        expect { generate(@dir, "invalid") }.to raise_error(
          InvalidDataTypeForAdapter,
          "SQLite doesn't support \"invalid\". Supported types are: binary.",
        )
      end

      private

      def generate(dir, data_type = "binary", database_adapter = "sqlite")
        MigrationGenerator.new.generate(DatabaseAdapter.from_string(database_adapter, data_type), dir)
      end
    end
  end
end
