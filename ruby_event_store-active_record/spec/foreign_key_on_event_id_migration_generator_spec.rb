# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/helpers/silence_stdout"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe ForeignKeyOnEventIdMigrationGenerator do
      around { |example| SilenceStdout.silence_stdout { example.run } }
      around do |example|
        begin
          @dir = Dir.mktmpdir(nil, "./")
          example.call
        ensure
          FileUtils.rm_r(@dir)
          FileUtils.rm_f(["./20221130213700_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb"])
        end
      end

      before { allow(Time).to receive(:now).and_return(Time.new(2022, 11, 30, 21, 37, 00)) }

      %w[mysql2 postgresql sqlite].each do |adapter|
        specify "it is created within specified directory" do
          migration_generator(adapter, @dir)

          expect(migration_exists?(@dir)).to be_truthy
        end

        specify "uses particular migration version" do
          migration_generator(adapter, @dir)

          expect(read_migration(@dir)).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
        end

        specify "uses particular migration version for rails 6.0" do
          skip unless ENV["BUNDLE_GEMFILE"]&.include?("rails_6_0")

          migration_generator(adapter, @dir)

          expect(read_migration(@dir)).to include("ActiveRecord::Migration[6.0]")
        end

        specify "uses particular migration version for rails 6.1" do
          skip unless ENV["BUNDLE_GEMFILE"]&.include?("rails_6_1")

          migration_generator(adapter, @dir)

          expect(read_migration(@dir)).to include("ActiveRecord::Migration[6.1]")
        end
      end

      context "when postgresql adapter is used" do
        specify "should do migration in two steps" do
          migration_generator('postgresql', @dir)
          expect(second_step_migration_exists?(@dir)).to be_truthy
          expect(generated_files_count(@dir)).to eq(2)
        end
      end

      %w[mysql2 sqlite].each do |adapter|
        context "when #{adapter} adapter is used" do
          specify "should do migration in single step" do
            migration_generator(adapter, @dir)
            expect(generated_files_count(@dir)).to eq(1)
          end
        end
      end

      specify "unsupported adapter raises error" do
        expect { migration_generator('unsupported', @dir) }.to raise_error(UnsupportedAdapter)
      end

      private

      def migration_generator(adapter, dir)
        ForeignKeyOnEventIdMigrationGenerator.new.call(adapter, dir)
      end

      def migration_exists?(dir)
        File.exist?("#{dir}/20221130213700_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb")
      end

      def read_migration(dir)
        File.read("#{dir}/20221130213700_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb")
      end

      def second_step_migration_exists?(dir)
        File.exist?("#{dir}/20221130213700_validate_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb")
      end

      def generated_files_count(dir)
        Dir[File.join(dir, '**', '*')].length
      end
    end
  end
end
