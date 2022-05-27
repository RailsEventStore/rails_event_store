require "spec_helper"
require "pp"
require "fakefs/safe"
require_relative "../../support/helpers/silence_stdout"

module RailsEventStoreActiveRecord
  RSpec.describe MigrationGenerator do
    around { |example| SilenceStdout.silence_stdout { example.run } }

    around do |example|
      FakeFS.with_fresh do
        FakeFS::FileSystem.clone(
          File.expand_path("../../lib/rails_event_store_active_record/generators/templates", __FILE__)
        )
        example.run
      end
    end

    before { allow(Time).to receive(:now).and_return(Time.new(2016, 8, 9, 22, 22, 22)) }

    let(:generator) { MigrationGenerator.new }

    subject do
      generator.create_migration
      File.read("db/migrate/20160809222222_create_event_store_events.rb")
    end

    it "uses particular migration version" do
      expect(subject).to match(/ActiveRecord::Migration\[4\.2\]$/)
    end

    it "uses binary data type for metadata" do
      expect(subject).to match(/t.binary\s+:metadata/)
    end

    it "uses binary data type for data" do
      expect(subject).to match(/t.binary\s+:data/)
    end

    context "when data_type option is specified" do
      let(:generator) { MigrationGenerator.new([], data_type: data_type) }

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

      context "with an invalid datatype" do
        let(:data_type) { "invalid" }

        it "raises an error" do
          expect { subject }.to raise_error(
            described_class::Error,
            "Invalid value for --data-type option. Supported for options are: binary, json, jsonb."
          )
        end
      end
    end
  end
end
