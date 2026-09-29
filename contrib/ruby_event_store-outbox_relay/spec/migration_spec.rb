# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe "create_event_store_outbox_tables migration" do
      helper = SpecHelper.new

      around do |example|
        helper.establish_database_connection
        helper.load_database_schema
        helper.load_outbox_schema
        example.run
      ensure
        helper.drop_outbox_schema
        helper.drop_database
      end

      let(:connection) { ::ActiveRecord::Base.connection }

      specify "creates the outbox tables and leaves event_store_events untouched" do
        expect(connection.tables).to include("event_store_outbox_messages", "event_store_outbox_dead_letters")
        expect(connection.columns(:event_store_events).map(&:name)).not_to include("published_at")
      end

      specify "indexes messages by when they are due" do
        index = connection.indexes(:event_store_outbox_messages).find { |i| i.name == "index_event_store_outbox_messages_due" }

        expect(index.columns).to eq(%w[next_attempt_at id])
      end

      specify "requires everything needed to deliver a message" do
        required = connection.columns(:event_store_outbox_messages).reject(&:null).map(&:name)

        expect(required).to match_array(%w[id event_id topic subscriber attempts next_attempt_at created_at])
      end

      specify "requires everything needed to explain a dead letter, except the error text" do
        required = connection.columns(:event_store_outbox_dead_letters).reject(&:null).map(&:name)

        expect(required).to match_array(%w[id event_id topic subscriber attempts error_class first_enqueued_at dead_at])
      end

      specify "starts a message at zero attempts" do
        Message.insert!({ event_id: SecureRandom.uuid, topic: "t", subscriber: "s", next_attempt_at: Time.now.utc, created_at: Time.now.utc })

        expect(Message.sole.attempts).to eq(0)
      end
    end
  end
end
