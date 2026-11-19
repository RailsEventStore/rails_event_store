# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe StreamsMetadataMigrationGenerator do
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
        path = StreamsMetadataMigrationGenerator.new.call(@dir)
        expect(path).to eq("#{@dir}/20261118213700_create_event_store_streams_metadata.rb")
        expect(File.read(path)).to include("ActiveRecord::Migration")
      end

      specify "returns path to migration file" do
        path, _ = StreamsMetadataMigrationGenerator.new.generate(@dir)
        expect(path).to eq("#{@dir}/20261118213700_create_event_store_streams_metadata.rb")
      end

      specify "uses particular migration version" do
        _, content = StreamsMetadataMigrationGenerator.new.generate(@dir)
        expect(content).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      specify "creates streams metadata table" do
        _, content = StreamsMetadataMigrationGenerator.new.generate(@dir)
        expect(content).to include("create_table(:event_store_streams_metadata, force: false)")
        expect(content).to include("t.string   :stream,            null: false, index: { unique: true }")
      end
    end
  end
end
