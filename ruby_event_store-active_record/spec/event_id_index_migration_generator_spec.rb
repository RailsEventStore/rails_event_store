# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/helpers/silence_stdout"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe EventIdIndexMigrationGenerator do
      around { |example| SilenceStdout.silence_stdout { example.run } }
      around do |example|
        begin
          @dir = Dir.mktmpdir(nil, "./")
          example.call
        ensure
          FileUtils.rm_r(@dir)
          FileUtils.rm_f(["./20221130213700_add_event_id_index_to_event_store_events_in_streams.rb"])
        end
      end

      before { allow(Time).to receive(:now).and_return(Time.new(2022, 11, 30, 21, 37, 00)) }

      specify "it is created within specified directory" do
        migration_generator(@dir)

        expect(migration_exists?(@dir)).to be_truthy
      end

      specify "returns path to migration file" do
        path = migration_generator(@dir)

        expected_path = "#{@dir}/20221130213700_add_event_id_index_to_event_store_events_in_streams.rb"
        expect(path).to match(expected_path)
      end

      specify "uses particular migration version" do
        migration_generator(@dir)

        expect(read_migration(@dir)).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      private

      def migration_generator(dir)
        EventIdIndexMigrationGenerator.new.call(dir)
      end

      def migration_exists?(dir)
        File.exist?("#{dir}/20221130213700_add_event_id_index_to_event_store_events_in_streams.rb")
      end

      def read_migration(dir)
        File.read("#{dir}/20221130213700_add_event_id_index_to_event_store_events_in_streams.rb")
      end
    end
  end
end
