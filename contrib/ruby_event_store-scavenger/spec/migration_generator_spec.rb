# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

module RubyEventStore
  module Scavenger
    ::RSpec.describe MigrationGenerator do
      specify "writes the migration" do
        Dir.mktmpdir do |dir|
          path = MigrationGenerator.new.call(dir, time: Time.utc(2026, 11, 18, 12, 30, 45))

          expect(path).to eq(File.join(dir, "20261118123045_create_event_store_scavenger_state.rb"))
          expect(File.read(path)).to eq(MigrationGenerator.new.migration_code)
        end
      end

      specify "timestamps with the current time by default" do
        Dir.mktmpdir do |dir|
          path = MigrationGenerator.new.call(dir)

          expect(File.basename(path)).to match(
            /\A#{Time.now.strftime("%Y%m%d")}\d{6}_create_event_store_scavenger_state\.rb\z/,
          )
        end
      end

      specify "migration code" do
        expect(MigrationGenerator.new.migration_code).to include(
          "class CreateEventStoreScavengerState < ActiveRecord::Migration[#{::ActiveRecord::Migration.current_version}]",
          "create_table(:event_store_scavenger_state",
        )
      end

      specify "creates the state table" do
        ::ActiveRecord::Migration.drop_table(State::TABLE)
        ::ActiveRecord::Migration.suppress_messages do
          TOPLEVEL_BINDING.eval(MigrationGenerator.new.migration_code)
          ::CreateEventStoreScavengerState.new.change
        end

        State.new.save(status: :idle, stream: nil, cursor: nil)
        expect(State.new.status.status).to eq(:idle)
      end
    end
  end
end
