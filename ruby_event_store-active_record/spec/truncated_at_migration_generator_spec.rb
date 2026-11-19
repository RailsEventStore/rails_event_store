# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe TruncatedAtMigrationGenerator do
      around do |example|
        begin
          @dir = Dir.mktmpdir(nil, "./")
          example.call
        ensure
          FileUtils.rm_r(@dir)
        end
      end

      before { allow(Time).to receive(:now).and_return(Time.new(2026, 11, 18, 21, 37, 00)) }

      specify "it is created within specified directory" do
        path = TruncatedAtMigrationGenerator.new.call(DatabaseAdapter.from_string("sqlite"), @dir)
        expect(path).to eq("#{@dir}/20261118213700_add_truncated_at_to_event_store_events_in_streams.rb")
        expect(File.read(path)).to include("ActiveRecord::Migration")
      end

      specify "returns path to migration file" do
        path, _ = generate(@dir)
        expect(path).to eq("#{@dir}/20261118213700_add_truncated_at_to_event_store_events_in_streams.rb")
      end

      specify "uses particular migration version" do
        _, content = generate(@dir)
        expect(content).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      specify "adds truncated_at column for every adapter" do
        %w[SQLite MySQL2 PostgreSQL].each do |adapter|
          _, content = generate(@dir, adapter)
          expect(content).to include(
            "add_column :event_store_events_in_streams, :truncated_at, :datetime, null: true, precision: 6",
          )
        end
      end

      specify "replaces stream and id index with partial one for SQLite adapter" do
        _, content = generate(@dir, "SQLite")
        expect(content).to include('name: "index_event_store_events_in_streams_on_stream_and_id_visible"')
        expect(content).to include('where: "truncated_at IS NULL"')
        expect(content).to include('name: "index_event_store_events_in_streams_on_stream_and_id",')
        expect(content).not_to include("disable_ddl_transaction!")
        expect(content).not_to include("algorithm: :concurrently")
      end

      specify "builds partial index before dropping the old one concurrently for PostgreSQL adapter" do
        _, content = generate(@dir, "PostgreSQL")
        up = content[/def up.*?\n  end/m]
        expect(content).to include("disable_ddl_transaction!")
        expect(up.index("add_index")).to be < up.index("remove_index")
        expect(up.scan("algorithm: :concurrently").size).to eq(2)
        expect(up).to include('where: "truncated_at IS NULL"')
        expect(up).to include('name: "index_event_store_events_in_streams_on_stream_and_id_visible"')
        expect(up).to include('name: "index_event_store_events_in_streams_on_stream_and_id",')
      end

      specify "keeps stream and id index for MySQL adapter" do
        _, content = generate(@dir, "MySQL2")
        expect(content).not_to include("add_index")
        expect(content).not_to include("remove_index")
        expect(content).not_to include("disable_ddl_transaction!")
      end

      private

      def generate(dir, database_adapter = "sqlite")
        TruncatedAtMigrationGenerator.new.generate(DatabaseAdapter.from_string(database_adapter), dir)
      end
    end
  end
end
