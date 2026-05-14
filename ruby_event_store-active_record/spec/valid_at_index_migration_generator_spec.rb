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
        end
      end

      before { allow(Time).to receive(:now).and_return(Time.new(2022, 11, 30, 21, 37, 00)) }

      specify "it is created within specified directory" do
        ValidAtIndexMigrationGenerator.new.call(@dir)
        expect(File.exist?("#{@dir}/20221130213700_add_valid_at_index_to_event_store_events.rb")).to be true
      end

      specify "returns path to migration file" do
        path, _ = ValidAtIndexMigrationGenerator.new.generate(@dir)
        expect(path).to eq("#{@dir}/20221130213700_add_valid_at_index_to_event_store_events.rb")
      end

      specify "uses particular migration version" do
        _, content = ValidAtIndexMigrationGenerator.new.generate(@dir)
        expect(content).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      specify "adds COALESCE index" do
        _, content = ValidAtIndexMigrationGenerator.new.generate(@dir)
        expect(content).to include('add_index :event_store_events,')
        expect(content).to include('"COALESCE(valid_at, created_at)",')
        expect(content).to include('name: "index_event_store_events_on_as_of",')
        expect(content).to include("algorithm: :concurrently")
      end

      specify "disables ddl transaction" do
        _, content = ValidAtIndexMigrationGenerator.new.generate(@dir)
        expect(content).to include("disable_ddl_transaction!")
      end

      specify "guards against duplicate index" do
        _, content = ValidAtIndexMigrationGenerator.new.generate(@dir)
        expect(content).to include(
          'unless index_exists?(:event_store_events, "COALESCE(valid_at, created_at)",',
        )
      end
    end
  end
end
