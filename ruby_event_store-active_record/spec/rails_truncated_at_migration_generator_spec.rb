# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/helpers/silence_stdout"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe RailsTruncatedAtMigrationGenerator do
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
        RailsTruncatedAtMigrationGenerator.start([], destination_root: @dir)
        File.read("#{@dir}/db/migrate/20160809222222_add_truncated_at_to_event_store_events_in_streams.rb")
      end

      it "uses particular migration version" do
        helper.establish_database_connection

        expect(subject).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
      end

      context "when sqlite adapter is used" do
        before { with_stubbed_adapter("sqlite") }

        it "replaces stream and id index with partial one" do
          expect(subject).to include(":truncated_at")
          expect(subject).to include('where: "truncated_at IS NULL"')
          expect(subject).not_to include("disable_ddl_transaction!")
        end
      end

      context "when mysql adapter is used" do
        before { with_stubbed_adapter("Mysql2") }

        it "adds column only" do
          expect(subject).to include(":truncated_at")
          expect(subject).not_to include("add_index")
        end
      end

      context "when postgresql adapter is used" do
        before { with_stubbed_adapter("postgresql") }

        it "replaces stream and id index concurrently" do
          expect(subject).to include('where: "truncated_at IS NULL"')
          expect(subject).to include("algorithm: :concurrently")
          expect(subject).to include("disable_ddl_transaction!")
        end
      end

      specify "unsupported adapter raises generator Error" do
        with_stubbed_adapter("not_a_supported_adapter")

        expect { RailsTruncatedAtMigrationGenerator.new([], destination_root: @dir) }.to raise_error(
          RailsTruncatedAtMigrationGenerator::Error,
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
