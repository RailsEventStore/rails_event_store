# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe ForeignKeyOnEventIdMigrationGenerator do
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
        ForeignKeyOnEventIdMigrationGenerator.new.call(DatabaseAdapter::SQLite.new, @dir)
        expect(File.exist?("#{@dir}/20221130213700_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb")).to be true
      end

      [DatabaseAdapter::MySQL, DatabaseAdapter::SQLite, DatabaseAdapter::PostgreSQL].each do |adapter_class|
        adapter = adapter_class.new
        specify "uses particular migration version for #{adapter}" do
          _, content = ForeignKeyOnEventIdMigrationGenerator.new.generate(adapter, @dir).first
          expect(content).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
        end
      end

      context "when postgresql adapter is used" do
        specify "should do migration in two steps" do
          migrations = ForeignKeyOnEventIdMigrationGenerator.new.generate(DatabaseAdapter::PostgreSQL.new, @dir)
          expect(migrations.length).to eq(2)
        end
      end

      [DatabaseAdapter::MySQL, DatabaseAdapter::SQLite].each do |adapter_class|
        adapter = adapter_class.new
        context "when #{adapter} adapter is used" do
          specify "should do migration in single step" do
            migrations = ForeignKeyOnEventIdMigrationGenerator.new.generate(adapter, @dir)
            expect(migrations.length).to eq(1)
          end
        end
      end
    end
  end
end
