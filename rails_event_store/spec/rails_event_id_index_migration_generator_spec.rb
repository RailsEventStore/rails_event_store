# frozen_string_literal: true

require "spec_helper"
require "pp"
require_relative "../../support/helpers/silence_stdout"

module RailsEventStore
  ::RSpec.describe RubyEventStore::ActiveRecord::RailsEventIdIndexMigrationGenerator do
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
      RubyEventStore::ActiveRecord::RailsEventIdIndexMigrationGenerator.start([], destination_root: @dir)
      File.read("#{@dir}/db/migrate/20160809222222_add_event_id_index_to_event_store_events_in_streams.rb")
    end

    it "uses particular migration version" do
      expect(subject).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
    end

    it "uses particular migration version for rails 6.1" do
      skip unless ENV["BUNDLE_GEMFILE"].include?("rails_6_1")
      expect(subject).to include("ActiveRecord::Migration[6.1]")
    end
  end
end
