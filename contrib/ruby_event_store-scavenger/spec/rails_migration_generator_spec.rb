# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "generators/ruby_event_store/scavenger/migration_generator"
require_relative "../../../support/helpers/silence_stdout"

module RubyEventStore
  module Scavenger
    ::RSpec.describe RailsMigrationGenerator, db: false do
      around { |example| SilenceStdout.silence_stdout { example.run } }

      around do |example|
        Dir.mktmpdir do |dir|
          @dir = dir
          example.run
        end
      end

      before { allow(Time).to receive(:now).and_return(Time.new(2016, 8, 9, 22, 22, 22)) }

      specify "writes the migration creating the state table" do
        RailsMigrationGenerator.start([], destination_root: @dir)

        expect(File.read("#{@dir}/db/migrate/20160809222222_create_event_store_scavenger_state.rb")).to eq(
          MigrationGenerator.new.migration_code,
        )
      end

      specify "namespace" do
        expect(RailsMigrationGenerator.namespace).to eq("ruby_event_store:scavenger:migration")
      end
    end
  end
end
