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

        expect(subject).to include(
          'add_index :event_store_events, "COALESCE(valid_at, created_at)", name: "index_event_store_events_on_as_of"',
        )
      end
    end
  end
end
