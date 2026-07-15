# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/helpers/silence_stdout"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe RailsStreamIdIndexMigrationGenerator do
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
        RailsStreamIdIndexMigrationGenerator.start([], destination_root: @dir)
        File.read("#{@dir}/db/migrate/20160809222222_add_stream_id_index_to_event_store_events_in_streams.rb")
      end

      it "uses particular migration version" do
        helper.establish_database_connection

        expect(subject).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      context "when sqlite adapter is used" do
        before { with_stubbed_adapter("sqlite") }

        it "includes stream id index" do
          expect(subject).to include("add_index :event_store_events_in_streams,")
          expect(subject).to include("[:stream, :id],")
          expect(subject).to include('name: "index_event_store_events_in_streams_on_stream_and_id"')
        end

        it "does not disable ddl transaction" do
          expect(subject).not_to include("disable_ddl_transaction!")
        end
      end

      context "when mysql adapter is used" do
        before { with_stubbed_adapter("Mysql2") }

        it "includes stream id index" do
          expect(subject).to include("add_index :event_store_events_in_streams,")
          expect(subject).to include("[:stream, :id],")
          expect(subject).to include('name: "index_event_store_events_in_streams_on_stream_and_id"')
        end

        it "does not disable ddl transaction" do
          expect(subject).not_to include("disable_ddl_transaction!")
        end
      end

      context "when postgresql adapter is used" do
        before { with_stubbed_adapter("postgresql") }

        it "includes stream id index" do
          expect(subject).to include("add_index :event_store_events_in_streams,")
          expect(subject).to include("[:stream, :id],")
          expect(subject).to include('name: "index_event_store_events_in_streams_on_stream_and_id"')
          expect(subject).to include("algorithm: :concurrently")
        end

        it "disables ddl transaction" do
          expect(subject).to include("disable_ddl_transaction!")
        end
      end

      specify "unsupported adapter raises generator Error" do
        with_stubbed_adapter("not_a_supported_adapter")

        expect {
          RailsStreamIdIndexMigrationGenerator.new([], destination_root: @dir)
        }.to raise_error(
          RailsStreamIdIndexMigrationGenerator::Error,
          'Unsupported adapter: "not_a_supported_adapter"',
        )
      end

      private

      def with_stubbed_adapter(name)
        allow(::ActiveRecord::Base).to receive(:connection).and_return(double(adapter_name: name))
      end
    end
  end
end
