# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/helpers/silence_stdout"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe RailsValidAtIndexMigrationGenerator do
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
        RailsValidAtIndexMigrationGenerator.start([], destination_root: @dir)
        File.read("#{@dir}/db/migrate/20160809222222_add_valid_at_index_to_event_store_events.rb")
      end

      it "uses particular migration version" do
        helper.establish_database_connection

        expect(subject).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      it "includes COALESCE index" do
        helper.establish_database_connection

        expect(subject).to include('add_index :event_store_events,')
        expect(subject).to include('"COALESCE(valid_at, created_at)",')
        expect(subject).to include('name: "index_event_store_events_on_as_of"')
        expect(subject).to include("if_not_exists: true")
      end

      it "uses concurrent algorithm for PostgreSQL" do
        helper.establish_database_connection
        skip unless DatabaseAdapter.from_string(::ActiveRecord::Base.connection.adapter_name).is_a?(DatabaseAdapter::PostgreSQL)

        expect(subject).to include("algorithm: :concurrently")
        expect(subject).to include("disable_ddl_transaction!")
      end

      it "uses inplace algorithm for MySQL" do
        helper.establish_database_connection
        skip unless DatabaseAdapter.from_string(::ActiveRecord::Base.connection.adapter_name).is_a?(DatabaseAdapter::MySQL)

        expect(subject).to include("algorithm: :inplace")
        expect(subject).not_to include("disable_ddl_transaction!")
      end

      it "uses no algorithm for SQLite" do
        helper.establish_database_connection
        skip unless DatabaseAdapter.from_string(::ActiveRecord::Base.connection.adapter_name).is_a?(DatabaseAdapter::SQLite)

        expect(subject).not_to include("algorithm:")
        expect(subject).not_to include("disable_ddl_transaction!")
      end
    end
  end
end
