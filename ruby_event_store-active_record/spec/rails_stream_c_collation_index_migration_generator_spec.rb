# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/helpers/silence_stdout"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe RailsStreamCCollationIndexMigrationGenerator do
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
        RailsStreamCCollationIndexMigrationGenerator.start([], destination_root: @dir)
        File.read("#{@dir}/db/migrate/20160809222222_add_stream_c_collation_index_to_event_store_events_in_streams.rb")
      end

      context "when postgresql adapter is used" do
        before { with_stubbed_adapter("postgresql") }

        it "uses particular migration version" do
          helper.establish_database_connection
          with_stubbed_adapter("postgresql")

          expect(subject).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
        end

        it "includes the stream COLLATE \"C\" index" do
          expect(subject).to include("add_index :event_store_events_in_streams,")
          expect(subject).to include(%q['stream COLLATE "C"',])
          expect(subject).to include('name: "index_event_store_events_in_streams_on_stream_c_collation"')
          expect(subject).to include("algorithm: :concurrently")
        end

        it "disables ddl transaction" do
          expect(subject).to include("disable_ddl_transaction!")
        end
      end

      %w[sqlite Mysql2].each do |unsupported_adapter|
        specify "#{unsupported_adapter} adapter raises generator Error" do
          with_stubbed_adapter(unsupported_adapter)

          expect { RailsStreamCCollationIndexMigrationGenerator.new([], destination_root: @dir) }.to raise_error(
            RailsStreamCCollationIndexMigrationGenerator::Error,
            /only applicable to PostgreSQL/,
          )
        end
      end

      specify "unsupported adapter raises generator Error" do
        with_stubbed_adapter("not_a_supported_adapter")

        expect { RailsStreamCCollationIndexMigrationGenerator.new([], destination_root: @dir) }.to raise_error(
          RailsStreamCCollationIndexMigrationGenerator::Error,
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
