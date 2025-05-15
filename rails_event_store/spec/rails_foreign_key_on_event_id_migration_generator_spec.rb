# frozen_string_literal: true

require "spec_helper"
require "pp"
require_relative "../../support/helpers/silence_stdout"

module RailsEventStore
  ::RSpec.describe RubyEventStore::ActiveRecord::RailsForeignKeyOnEventIdMigrationGenerator do
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
      generate_migration
      File.read("#{@dir}/db/migrate/20160809222222_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb")
    end

    it "uses particular migration version" do
      expect(subject).to include("ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]")
    end

    context "when postgresql adapter is used" do
      specify "should do migration in two steps" do
        allow(::ActiveRecord::Base).to receive(:connection).and_return(double(adapter_name: "postgresql"))

        generate_migration

        expect(second_step_migration_exists?(@dir)).to be_truthy
        expect(generated_files_count(@dir)).to eq(2)
      end

      specify "should do the same for postgis" do
        allow(::ActiveRecord::Base).to receive(:connection).and_return(double(adapter_name: "postgis"))

        generate_migration

        expect(second_step_migration_exists?(@dir)).to be_truthy
        expect(generated_files_count(@dir)).to eq(2)
      end
    end

    %w[mysql2 sqlite].each do |adapter|
      context "when #{adapter} adapter is used" do
        before { allow(::ActiveRecord::Base).to receive(:connection).and_return(double(adapter_name: adapter)) }

        specify "should do migration in single step" do
          generate_migration
          expect(second_step_migration_exists?(@dir)).to be_falsey
          expect(generated_files_count(@dir)).to eq(1)
        end
      end
    end

    specify "Unsupported adapter is used" do
      allow(::ActiveRecord::Base).to receive(:connection).and_return(double(adapter_name: "not_a_supported_adapter"))

      expect { generate_migration }.to output(/Unsupported adapter/).to_stderr
    end

    def generate_migration
      RubyEventStore::ActiveRecord::RailsForeignKeyOnEventIdMigrationGenerator.start([], destination_root: @dir)
    end

    def second_step_migration_exists?(dir)
      File.exist?(
        "#{dir}/db/migrate/20160809222223_validate_add_foreign_key_on_event_id_to_event_store_events_in_streams.rb",
      )
    end

    def generated_files_count(dir)
      Dir[File.join(dir, "db/migrate", "*")].length
    end
  end
end
