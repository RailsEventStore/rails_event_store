# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe "add_published_at_to_event_store_events migration" do
      helper = SpecHelper.new
      event_klass = RubyEventStore::ActiveRecord::WithDefaultModels.new.call.first

      around do |example|
        helper.establish_database_connection
        helper.load_database_schema
        example.run
      ensure
        helper.drop_database
      end

      specify "existing rows become published (published_at NOT NULL) after migrating" do
        skip "SQLite can't ADD COLUMN with a non-constant default on a non-empty table" unless helper.postgres? || helper.mysql?

        event_klass.insert({
          event_id: SecureRandom.uuid,
          event_type: "PreExisting",
          data: "{}",
          metadata: "{}",
          created_at: Time.now.utc,
        })
        pre_existing = event_klass.first

        helper.load_outbox_schema
        helper.reset_column_information

        expect(pre_existing.reload.published_at).not_to be_nil
      end

      specify "the unpublished index exists after migrating" do
        helper.load_outbox_schema

        indexes = ::ActiveRecord::Base.connection.indexes(:event_store_events)
        expect(indexes.map(&:name)).to include("index_event_store_events_unpublished")
      end
    end
  end
end
