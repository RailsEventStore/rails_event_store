require "spec_helper"
require_relative "../../support/helpers/silence_stdout"

module RubyEventStore
  module ActiveRecord
    RSpec.describe MigrationGenerator do
      around { |example| SilenceStdout.silence_stdout { example.run } }

      before { allow(Time).to receive(:now).and_return(Time.new(2022, 11, 30, 21, 37, 00)) }

      specify "it is created at default migration path when path is not specified" do
        dir = FileUtils.mkdir_p("./db/migrate").first

        RubyEventStore::ActiveRecord::MigrationGenerator.new.call("binary")

        expect(migration_exists?(dir)).to be_truthy
      ensure
        FileUtils.rm_rf(dir)
        FileUtils.rmdir("./db")
      end

      specify "it is created within specified directory" do
        dir = Dir.mktmpdir(nil, "./")

        migration_generator(dir)

        expect(migration_exists?(dir)).to be_truthy
      ensure
        FileUtils.rm_r(dir)
      end

      specify "returns path to migration file" do
        dir = Dir.mktmpdir(nil, "./")

        path = migration_generator(dir)

        expect(path).to match(File.expand_path("../#{dir}", __dir__))
      ensure
        FileUtils.rm_r(dir)
      end

      specify "uses particular migration version" do
        dir = Dir.mktmpdir(nil, "./")

        migration_generator(dir)

        expect(read_migration(dir)).to match(/ActiveRecord::Migration\[4\.2\]$/)
      ensure
        FileUtils.rm_r(dir)
      end

      specify "creates migration with binary data type" do
        dir = Dir.mktmpdir(nil, "./")

        migration_generator(dir, "binary")

        expect(read_migration(dir)).to match(/t.binary\s+:data/)
        expect(read_migration(dir)).to match(/t.binary\s+:metadata/)
      ensure
        FileUtils.rm_r(dir)
      end

      specify "creates migration with json data type" do
        dir = Dir.mktmpdir(nil, "./")

        migration_generator(dir, "json")

        expect(read_migration(dir)).to match(/t.json\s+:data/)
        expect(read_migration(dir)).to match(/t.json\s+:metadata/)
      ensure
        FileUtils.rm_r(dir)
      end

      specify "creates migration with jsonb data type" do
        dir = Dir.mktmpdir(nil, "./")

        migration_generator(dir, "jsonb")

        expect(read_migration(dir)).to match(/t.jsonb\s+:data/)
        expect(read_migration(dir)).to match(/t.jsonb\s+:metadata/)
      ensure
        FileUtils.rm_r(dir)
      end

      specify "raises error when data type is not supported" do
        dir = Dir.mktmpdir(nil, "./")

        expect { migration_generator(dir, "invalid") }.to raise_error(
          ArgumentError,
          "Invalid value for --data-type option. Supported for options are: binary, json, jsonb."
        )
      ensure
        FileUtils.rm_r(dir)
      end

      private

      def migration_generator(dir, data_type = "binary")
        RubyEventStore::ActiveRecord::MigrationGenerator.new.call(data_type, migration_path: dir)
      end

      def migration_exists?(dir)
        File.exist?("#{dir}/20221130213700_create_event_store_events.rb")
      end

      def read_migration(dir)
        File.read("#{dir}/20221130213700_create_event_store_events.rb")
      end
    end
  end
end
