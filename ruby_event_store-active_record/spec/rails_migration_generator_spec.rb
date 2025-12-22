# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/helpers/silence_stdout"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe RailsMigrationGenerator do
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
        RailsMigrationGenerator.start([], destination_root: @dir)
        File.read("#{@dir}/db/migrate/20160809222222_create_event_store_events.rb")
      end

      it "uses particular migration version" do
        helper.establish_database_connection

        expect(subject).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      context "when unsupported adapter" do
        it "raises an error" do
          with_stubbed_adapter("kakadudu")

          expect { RailsMigrationGenerator.new([], data_type: nil) }.to raise_error RailsMigrationGenerator::Error,
                      'Unsupported adapter: "kakadudu"'
        end
      end

      context "when postgresql adapter is used and data_type option is specified" do
        before { with_stubbed_adapter("postgresql") }

        subject do
          RailsMigrationGenerator.start(["--data-type=#{data_type}"], destination_root: @dir)
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
        before { with_stubbed_adapter("Mysql2") }

        subject do
          RailsMigrationGenerator.start(["--data-type=#{data_type}"], destination_root: @dir)
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

        context "when jsonb type is provided" do
          let(:data_type) { "jsonb" }

          it "raises an error" do
            expect {
              RailsMigrationGenerator.new([], data_type: data_type)
            }.to raise_error RailsMigrationGenerator::Error,
                        "Invalid value for --data-type option. Supported for options are: binary, json."
          end
        end
      end

      context "when sqlite adapter is used and data_type option is specified" do
        before { with_stubbed_adapter("sqlite") }

        subject do
          RailsMigrationGenerator.start(["--data-type=#{data_type}"], destination_root: @dir)
          File.read("#{@dir}/db/migrate/20160809222222_create_event_store_events.rb")
        end

        context "with a binary datatype" do
          let(:data_type) { "binary" }

          it { is_expected.to match(/t.binary\s+:metadata/) }
          it { is_expected.to match(/t.binary\s+:data/) }
        end

        context "when json type is provided" do
          let(:data_type) { "json" }

          it "raises an error" do
            expect {
              RailsMigrationGenerator.new([], data_type: data_type)
            }.to raise_error RailsMigrationGenerator::Error,
                        "Invalid value for --data-type option. Supported for options are: binary."
          end
        end

        context "when jsonb type is provided" do
          let(:data_type) { "jsonb" }

          it "raises an error" do
            expect {
              RailsMigrationGenerator.new([], data_type: data_type)
            }.to raise_error RailsMigrationGenerator::Error,
                        "Invalid value for --data-type option. Supported for options are: binary."
          end
        end

        context "with an invalid datatype" do
          let(:data_type) { "invalid" }

          it "raises an error" do
            expect { RailsMigrationGenerator.new([], data_type: data_type) }.to raise_error(
              RailsMigrationGenerator::Error,
              "Invalid value for --data-type option. Supported for options are: binary.",
            )
          end
        end
      end

      private

      def with_stubbed_adapter(name)
        allow(::ActiveRecord::Base).to receive(:connection).and_return(double(adapter_name: name))
      end
    end
  end
end
