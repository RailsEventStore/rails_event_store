# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe ValidAtIndexMigrationGenerator do
      around do |example|
        begin
          @dir = Dir.mktmpdir(nil, "./")
          example.call
        ensure
          FileUtils.rm_r(@dir)
          FileUtils.rm_f("./20221130213700_add_valid_at_index_to_event_store_events.rb")
        end
      end

      before { allow(Time).to receive(:now).and_return(Time.new(2022, 11, 30, 21, 37, 00)) }

      shared_examples "valid_at index migration generator" do
        specify "it is created within specified directory" do
          path = ValidAtIndexMigrationGenerator.new.call(adapter, @dir)
          expect(path).to eq("#{@dir}/20221130213700_add_valid_at_index_to_event_store_events.rb")
          expect(File.read(path)).to include("ActiveRecord::Migration")
        end

        specify "returns path to migration file" do
          path, _ = ValidAtIndexMigrationGenerator.new.generate(adapter, @dir)
          expect(path).to eq("#{@dir}/20221130213700_add_valid_at_index_to_event_store_events.rb")
        end

        specify "uses particular migration version" do
          _, content = ValidAtIndexMigrationGenerator.new.generate(adapter, @dir)
          expect(content).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
        end

        specify "adds COALESCE index" do
          _, content = ValidAtIndexMigrationGenerator.new.generate(adapter, @dir)
          expect(content).to include('add_index :event_store_events,')
          expect(content).to include('"COALESCE(valid_at, created_at)",')
          expect(content).to include('name: "index_event_store_events_on_as_of"')
        end

        specify "guards against duplicate index" do
          _, content = ValidAtIndexMigrationGenerator.new.generate(adapter, @dir)
          expect(content).to include(
            'unless index_exists?(:event_store_events, "COALESCE(valid_at, created_at)",',
          )
        end
      end

      describe "PostgreSQL" do
        let(:adapter) { DatabaseAdapter.from_string("PostgreSQL") }

        include_examples "valid_at index migration generator"

        specify "uses concurrent algorithm" do
          _, content = ValidAtIndexMigrationGenerator.new.generate(adapter, @dir)
          expect(content).to include("algorithm: :concurrently")
        end

        specify "disables ddl transaction" do
          _, content = ValidAtIndexMigrationGenerator.new.generate(adapter, @dir)
          expect(content).to include("disable_ddl_transaction!")
        end
      end

      describe "MySQL" do
        let(:adapter) { DatabaseAdapter.from_string("MySQL2") }

        include_examples "valid_at index migration generator"

        specify "uses inplace algorithm" do
          _, content = ValidAtIndexMigrationGenerator.new.generate(adapter, @dir)
          expect(content).to include("algorithm: :inplace")
        end

        specify "does not disable ddl transaction" do
          _, content = ValidAtIndexMigrationGenerator.new.generate(adapter, @dir)
          expect(content).not_to include("disable_ddl_transaction!")
        end
      end

      describe "SQLite" do
        let(:adapter) { DatabaseAdapter.from_string("sqlite") }

        include_examples "valid_at index migration generator"

        specify "does not specify algorithm" do
          _, content = ValidAtIndexMigrationGenerator.new.generate(adapter, @dir)
          expect(content).not_to include("algorithm:")
        end

        specify "does not disable ddl transaction" do
          _, content = ValidAtIndexMigrationGenerator.new.generate(adapter, @dir)
          expect(content).not_to include("disable_ddl_transaction!")
        end
      end
    end
  end
end
