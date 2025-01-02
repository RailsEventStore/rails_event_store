# frozen_string_literal: true

require "spec_helper"
require "pp"
require_relative "../../support/helpers/silence_stdout"

module RailsEventStore
  ::RSpec.describe RubyEventStore::ActiveRecord::RailsMigrationGenerator do
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
      RubyEventStore::ActiveRecord::RailsMigrationGenerator.start([], destination_root: @dir)
      File.read("#{@dir}/db/migrate/20160809222222_create_event_store_events.rb")
    end

    it "uses particular migration version" do
      expect(subject).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
    end

    it "uses particular migration version for rails 6.1" do
      skip unless ENV["BUNDLE_GEMFILE"].include?("rails_6_1")
      expect(subject).to include("ActiveRecord::Migration[6.1]")
    end

    context "when postgresql adapter is used and data_type option is specified" do
      before { allow(::ActiveRecord::Base).to receive(:connection).and_return(double(adapter_name: "postgresql")) }

      subject do
        RubyEventStore::ActiveRecord::RailsMigrationGenerator.start(
          ["--data-type=#{data_type}"],
          destination_root: @dir,
        )
        File.read("#{@dir}/db/migrate/20160809222222_create_event_store_events.rb")
      end

      context "with a binary datatype" do
        let(:data_type) { "binary" }
        it { is_expected.to match(/t.binary\s+:metadata/) }
        it { is_expected.to match(/t.binary\s+:data/) }
      end

      context "with a json datatype" do
        let(:data_type) { "json" }
        it { is_expected.to match(/t.json\s+:metadata/) }
        it { is_expected.to match(/t.json\s+:data/) }
      end

      context "with a jsonb datatype" do
        let(:data_type) { "jsonb" }
        it { is_expected.to match(/t.jsonb\s+:metadata/) }
        it { is_expected.to match(/t.jsonb\s+:data/) }
      end
    end

    context "when mysql adapter is used and data_type option is specified" do
      before { allow(::ActiveRecord::Base).to receive(:connection).and_return(double(adapter_name: "Mysql2")) }

      subject do
        RubyEventStore::ActiveRecord::RailsMigrationGenerator.start(
          ["--data-type=#{data_type}"],
          destination_root: @dir,
        )
        File.read("#{@dir}/db/migrate/20160809222222_create_event_store_events.rb")
      end

      context "with a binary datatype" do
        let(:data_type) { "binary" }
        it { is_expected.to match(/t.binary\s+:metadata/) }
        it { is_expected.to match(/t.binary\s+:data/) }
      end

      context "with json datatype" do
        let(:data_type) { "json" }
        it { is_expected.to match(/t.json\s+:metadata/) }
        it { is_expected.to match(/t.json\s+:data/) }
      end

      context "jsonb type is not used when adapter is not postgres" do
        let(:data_type) { "jsonb" }
        it "raises an error" do
          expect {
            RubyEventStore::ActiveRecord::RailsMigrationGenerator.new([], data_type: data_type)
          }.to raise_error RubyEventStore::ActiveRecord::RailsMigrationGenerator::Error,
                      "Invalid value for --data-type option. Supported for options are: binary, json."
        end
      end
    end

    context "when sqlite adapter is used and data_type option is specified" do
      subject do
        RubyEventStore::ActiveRecord::RailsMigrationGenerator.start(
          ["--data-type=#{data_type}"],
          destination_root: @dir,
        )
        File.read("#{@dir}/db/migrate/20160809222222_create_event_store_events.rb")
      end

      context "with a binary datatype" do
        let(:data_type) { "binary" }
        it { is_expected.to match(/t.binary\s+:metadata/) }
        it { is_expected.to match(/t.binary\s+:data/) }
      end

      context "json type is not used when adapter is not postgres" do
        let(:data_type) { "json" }

        it "raises an error" do
          expect {
            RubyEventStore::ActiveRecord::RailsMigrationGenerator.new([], data_type: data_type)
          }.to raise_error RubyEventStore::ActiveRecord::RailsMigrationGenerator::Error,
                      "Invalid value for --data-type option. Supported for options are: binary."
        end
      end

      context "jsonb type is not used when adapter is not postgres" do
        let(:data_type) { "jsonb" }

        it "raises an error" do
          expect {
            RubyEventStore::ActiveRecord::RailsMigrationGenerator.new([], data_type: data_type)
          }.to raise_error RubyEventStore::ActiveRecord::RailsMigrationGenerator::Error,
                      "Invalid value for --data-type option. Supported for options are: binary."
        end
      end

      context "with an invalid datatype" do
        let(:data_type) { "invalid" }

        it "raises an error" do
          expect { RubyEventStore::ActiveRecord::RailsMigrationGenerator.new([], data_type: data_type) }.to raise_error(
            RubyEventStore::ActiveRecord::RailsMigrationGenerator::Error,
            "Invalid value for --data-type option. Supported for options are: binary.",
          )
        end
      end
    end
  end
end
