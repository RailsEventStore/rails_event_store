# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/helpers/silence_stdout"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe ValidAtIndexMigrationGenerator do
      around { |example| SilenceStdout.silence_stdout { example.run } }

      around do |example|
        begin
          @dir = Dir.mktmpdir(nil, "./")
          example.call
        ensure
          FileUtils.rm_r(@dir)
          FileUtils.rm_f(["./20221130213700_add_valid_at_index_to_event_store_events.rb"])
        end
      end

      before { allow(Time).to receive(:now).and_return(Time.new(2022, 11, 30, 21, 37, 00)) }

      specify "it is created within specified directory" do
        migration_generator(@dir)

        expect(migration_exists?(@dir)).to be_truthy
      end

      specify "returns path to migration file" do
        path = migration_generator(@dir)

        expected_path = "#{@dir}/20221130213700_add_valid_at_index_to_event_store_events.rb"
        expect(path).to match(expected_path)
      end

      specify "uses particular migration version" do
        migration_generator(@dir)

        expect(read_migration(@dir)).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      specify "adds COALESCE index" do
        migration_generator(@dir)

        expect(read_migration(@dir)).to include('add_index :event_store_events,')
        expect(read_migration(@dir)).to include('"COALESCE(valid_at, created_at)",')
        expect(read_migration(@dir)).to include('name: "index_event_store_events_on_as_of",')
        expect(read_migration(@dir)).to include("algorithm: :concurrently")
      end

      specify "disables ddl transaction" do
        migration_generator(@dir)

        expect(read_migration(@dir)).to include("disable_ddl_transaction!")
      end

      specify "guards against duplicate index" do
        migration_generator(@dir)

        expect(read_migration(@dir)).to include(
          'unless index_exists?(:event_store_events, "COALESCE(valid_at, created_at)",',
        )
      end

      private

      def migration_generator(dir)
        ValidAtIndexMigrationGenerator.new.call(dir)
      end

      def migration_exists?(dir)
        File.exist?("#{dir}/20221130213700_add_valid_at_index_to_event_store_events.rb")
      end

      def read_migration(dir)
        File.read("#{dir}/20221130213700_add_valid_at_index_to_event_store_events.rb")
      end
    end
  end
end
