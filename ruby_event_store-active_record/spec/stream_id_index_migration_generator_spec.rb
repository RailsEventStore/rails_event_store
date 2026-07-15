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
        path = StreamIdIndexMigrationGenerator.new.call(@dir)
        expect(path).to eq("#{@dir}/20221130213700_add_stream_id_index_to_event_store_events_in_streams.rb")
        expect(File.read(path)).to include("ActiveRecord::Migration")
      end

      specify "returns path to migration file" do
        path, _ = StreamIdIndexMigrationGenerator.new.generate(@dir)
        expect(path).to eq("#{@dir}/20221130213700_add_stream_id_index_to_event_store_events_in_streams.rb")
      end

      specify "uses particular migration version" do
        _, content = StreamIdIndexMigrationGenerator.new.generate(@dir)
        expect(content).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      specify "includes stream id index" do
        _, content = StreamIdIndexMigrationGenerator.new.generate(@dir)
        expect(content).to include("add_index :event_store_events_in_streams,")
        expect(content).to include("[:stream, :id],")
        expect(content).to include('name: "index_event_store_events_in_streams_on_stream_and_id"')
        expect(content).to include("options[:algorithm] = :concurrently if postgresql?")
      end

      specify "disables ddl transaction conditionally" do
        _, content = StreamIdIndexMigrationGenerator.new.generate(@dir)
        expect(content).to include("disable_ddl_transaction! if ActiveRecord::Base.connection.adapter_name.downcase == \"postgresql\"")
      end

      specify "guards against duplicate index" do
        _, content = StreamIdIndexMigrationGenerator.new.generate(@dir)
        expect(content).to include(
          'unless index_exists?(:event_store_events_in_streams, [:stream, :id],',
        )
      end

      specify "uses runtime postgresql check" do
        _, content = StreamIdIndexMigrationGenerator.new.generate(@dir)
        expect(content).to include("def postgresql?")
        expect(content).to include("connection.adapter_name.downcase == \"postgresql\"")
      end
    end
  end
end
