# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe StreamCCollationIndexMigrationGenerator do
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
        path = StreamCCollationIndexMigrationGenerator.new.call(@dir)

        expect(path).to eq("#{@dir}/20221130213700_add_stream_c_collation_index_to_event_store_events_in_streams.rb")
        expect(File.read(path)).to include("ActiveRecord::Migration")
      end

      specify "returns path to migration file" do
        path, _ = generate(@dir)

        expect(path).to eq("#{@dir}/20221130213700_add_stream_c_collation_index_to_event_store_events_in_streams.rb")
      end

      specify "uses particular migration version" do
        _, content = generate(@dir)

        expect(content).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      specify "includes the stream COLLATE \"C\" index" do
        _, content = generate(@dir)

        expect(content).to include("add_index :event_store_events_in_streams,")
        expect(content).to include(%q['stream COLLATE "C"',])
        expect(content).to include('name: "index_event_store_events_in_streams_on_stream_c_collation"')
      end

      specify "builds the index concurrently, outside the ddl transaction" do
        _, content = generate(@dir)

        expect(content).to include("algorithm: :concurrently")
        expect(content).to include("disable_ddl_transaction!")
      end

      specify "guards against duplicate index" do
        _, content = generate(@dir)

        expect(content).to include("if_not_exists: true")
      end

      private

      def generate(dir)
        StreamCCollationIndexMigrationGenerator.new.generate(dir)
      end
    end
  end
end
