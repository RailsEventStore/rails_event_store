# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/helpers/silence_stdout"
require "rake"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe "migration_tasks.rake", mutant: false do
      before do
        allow(Time).to receive(:now).and_return(Time.new(2022, 11, 30, 21, 37, 00))
        allow(::ActiveRecord::Base).to receive(:connection).and_return(double(adapter_name: "PostgreSQL"))

        load File.join(
               File.expand_path("../../lib/ruby_event_store/active_record/tasks", __FILE__) + "/migration_tasks.rake",
             )
        Rake::Task["db:migrations:copy"].reenable
      end

      specify "custom path provided" do
        with_custom_directory do |dir|
          SilenceStdout.silence_stdout { Rake::Task["db:migrations:copy"].invoke }

          expect_migration_file_in_directory(dir)
        end
      end

      specify "no path provided" do
        with_default_directory do
          SilenceStdout.silence_stdout { Rake::Task["db:migrations:copy"].invoke }

          expect_migration_file_in_directory("db/migrate")
        end
      end

      specify "truncated_at migration" do
        Rake::Task["db:migrations:add_truncated_at"].reenable
        with_custom_directory do |dir|
          SilenceStdout.silence_stdout { Rake::Task["db:migrations:add_truncated_at"].invoke }

          path = File.join(dir, "20221130213700_add_truncated_at_to_event_store_events_in_streams.rb")
          expect(File).to exist(File.join(File.expand_path("../../", __FILE__), path))
          expect(File.read(File.join(File.expand_path("../../", __FILE__), path))).to include("algorithm: :concurrently")
        end
      end

      specify "streams metadata migration" do
        Rake::Task["db:migrations:add_streams_metadata"].reenable
        with_custom_directory do |dir|
          SilenceStdout.silence_stdout { Rake::Task["db:migrations:add_streams_metadata"].invoke }

          expect(File).to exist(
            File.join(File.expand_path("../../", __FILE__), dir, "20221130213700_create_event_store_streams_metadata.rb"),
          )
        end
      end

      def expect_migration_file_in_directory(directory)
        expect(File).to exist(
          File.join(File.expand_path("../../", __FILE__), directory, "20221130213700_create_event_store_events.rb"),
        )
      end

      def with_custom_directory
        Dir.mktmpdir(nil, "./") do |dir|
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with("DATA_TYPE").and_return("jsonb")
          allow(ENV).to receive(:[]).with("MIGRATION_PATH").and_return(dir)
          yield(dir[1..-1])
        end
      end

      def with_default_directory
        dir = FileUtils.mkdir_p("./db/migrate").first
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("DATA_TYPE").and_return("jsonb")
        yield
      ensure
        FileUtils.rm_rf(dir)
        FileUtils.rmdir("./db")
      end
    end
  end
end
