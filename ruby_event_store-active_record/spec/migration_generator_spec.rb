require "spec_helper"
require "pp"
require_relative "../../support/helpers/silence_stdout"

module RubyEventStore
  module ActiveRecord
    RSpec.describe MigrationGenerator do
      around { |example| SilenceStdout.silence_stdout { example.run } }

      around do |example|
        @dir = Dir.mktmpdir(nil, "./")
        example.call
        FileUtils.rm_r(@dir)
      end

      before { allow(Time).to receive(:now).and_return(Time.new(2016, 8, 9, 22, 22, 22)) }

      let(:generator) { MigrationGenerator.new }

      subject do
        MigrationGenerator.start([], destination_root: @dir)
        File.read("#{@dir}/db/migrate/20160809222222_create_event_store_events.rb")
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
        subject do
          MigrationGenerator.start(["--data-type=#{data_type}"], destination_root: @dir)
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

        context "with an invalid datatype" do
          let(:data_type) { "invalid" }

          it "raises an error" do
            expect { MigrationGenerator.new([], data_type: data_type) }.to raise_error(
              MigrationGenerator::Error,
              "Invalid value for --data-type option. Supported for options are: binary, json, jsonb."
            )
          end
        end
      end
    end
  end
end
