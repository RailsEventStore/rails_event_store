# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe EventIdIndexMigrationGenerator do
      around do |example|
        begin
          @dir = Dir.mktmpdir(nil, "./")
          example.call
        ensure
          FileUtils.rm_r(@dir)
          FileUtils.rm_f("./20221130213700_add_event_id_index_to_event_store_events_in_streams.rb")
        end
      end

      before { allow(Time).to receive(:now).and_return(Time.new(2022, 11, 30, 21, 37, 00)) }

      specify "it is created within specified directory" do
        path = EventIdIndexMigrationGenerator.new.call(@dir)
        expect(path).to eq("#{@dir}/20221130213700_add_event_id_index_to_event_store_events_in_streams.rb")
        expect(File.read(path)).to include("ActiveRecord::Migration")
      end

      specify "returns path to migration file" do
        path, _ = EventIdIndexMigrationGenerator.new.generate(@dir)
        expect(path).to eq("#{@dir}/20221130213700_add_event_id_index_to_event_store_events_in_streams.rb")
      end

      specify "uses particular migration version" do
        _, content = EventIdIndexMigrationGenerator.new.generate(@dir)
        expect(content).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end
    end
  end
end
