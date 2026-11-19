# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/helpers/silence_stdout"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe RailsStreamsMetadataMigrationGenerator do
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
        RailsStreamsMetadataMigrationGenerator.start([], destination_root: @dir)
        File.read("#{@dir}/db/migrate/20160809222222_create_event_store_streams_metadata.rb")
      end

      it "uses particular migration version" do
        expect(subject).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      it "creates streams metadata table" do
        expect(subject).to include("create_table(:event_store_streams_metadata, force: false)")
      end
    end
  end
end
