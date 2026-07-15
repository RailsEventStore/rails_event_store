# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe StreamIdIndexMigrationGenerator do
      around do |example|
        begin
          @dir = Dir.mktmpdir(nil, "./")
          example.call
        ensure
          FileUtils.rm_r(@dir)
          FileUtils.rm_f("./20221130213700_add_stream_id_index_to_event_store_events_in_streams.rb")
        end
      end

      before { allow(Time).to receive(:now).and_return(Time.new(2022, 11, 30, 21, 37, 00)) }

      specify "it is created within specified directory" do
        path = StreamIdIndexMigrationGenerator.new.call(DatabaseAdapter.from_string("sqlite", "binary"), @dir)
        expect(path).to eq("#{@dir}/20221130213700_add_stream_id_index_to_event_store_events_in_streams.rb")
        expect(File.read(path)).to include("ActiveRecord::Migration")
      end

      specify "returns path to migration file" do
        path, _ = generate(@dir)
        expect(path).to eq("#{@dir}/20221130213700_add_stream_id_index_to_event_store_events_in_streams.rb")
      end

      specify "uses particular migration version" do
        _, content = generate(@dir)
        expect(content).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      specify "includes stream id index for SQLite adapter" do
        _, content = generate(@dir, "SQLite")
        expect(content).to include("add_index :event_store_events_in_streams,")
        expect(content).to include("[:stream, :id],")
        expect(content).to include('name: "index_event_store_events_in_streams_on_stream_and_id"')
      end

      specify "includes stream id index for MySQL adapter" do
        _, content = generate(@dir, "MySQL2")
        expect(content).to include("add_index :event_store_events_in_streams,")
        expect(content).to include("[:stream, :id],")
        expect(content).to include('name: "index_event_store_events_in_streams_on_stream_and_id"')
      end

      specify "includes stream id index for PostgreSQL adapter" do
        _, content = generate(@dir, "PostgreSQL")
        expect(content).to include("add_index :event_store_events_in_streams,")
        expect(content).to include("[:stream, :id],")
        expect(content).to include('name: "index_event_store_events_in_streams_on_stream_and_id"')
        expect(content).to include("algorithm: :concurrently")
      end

      specify "disables ddl transaction for PostgreSQL adapter" do
        _, content = generate(@dir, "PostgreSQL")
        expect(content).to include("disable_ddl_transaction!")
      end

      specify "does not disable ddl transaction for MySQL adapter" do
        _, content = generate(@dir, "MySQL2")
        expect(content).not_to include("disable_ddl_transaction!")
      end

      specify "does not disable ddl transaction for SQLite adapter" do
        _, content = generate(@dir, "SQLite")
        expect(content).not_to include("disable_ddl_transaction!")
      end

      specify "guards against duplicate index" do
        _, content = generate(@dir)
        expect(content).to include("if_not_exists: true")
      end

      private

      def generate(dir, database_adapter = "sqlite")
        StreamIdIndexMigrationGenerator.new.generate(DatabaseAdapter.from_string(database_adapter, "binary"), dir)
      end
    end
  end
end
