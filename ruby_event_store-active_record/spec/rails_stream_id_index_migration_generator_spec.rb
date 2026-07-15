# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/helpers/silence_stdout"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe RailsStreamIdIndexMigrationGenerator do
      helper = SpecHelper.new

      around { |example| SilenceStdout.silence_stdout { example.run } }

      around do |example|
        begin
          @dir = Dir.mktmpdir(nil, "./")
          example.call
        ensure
          FileUtils.rm_r(@dir)
        end
      end

      before { allow(Time).to receive(:now).and_return(Time.new(2016, 8, 9, 22, 22, 22)) }

      subject do
        RailsStreamIdIndexMigrationGenerator.start([], destination_root: @dir)
        File.read("#{@dir}/db/migrate/20160809222222_add_stream_id_index_to_event_store_events_in_streams.rb")
      end

      it "uses particular migration version" do
        helper.establish_database_connection

        expect(subject).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      it "includes stream id index" do
        helper.establish_database_connection

        expect(subject).to include("add_index :event_store_events_in_streams,")
        expect(subject).to include("[:stream, :id],")
        expect(subject).to include('name: "index_event_store_events_in_streams_on_stream_and_id",')
        expect(subject).to include("algorithm: :concurrently")
      end

      it "disables ddl transaction" do
        helper.establish_database_connection

        expect(subject).to include("disable_ddl_transaction!")
      end
    end
  end
end
