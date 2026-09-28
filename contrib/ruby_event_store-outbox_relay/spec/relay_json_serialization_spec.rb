# frozen_string_literal: true

require "spec_helper"
require "securerandom"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe "Relay against a json/jsonb data or metadata column" do
      helper = SpecHelper.new
      around { |example| helper.run_lifecycle { example.run } }

      # A fresh model class, never touched by RubyEventStore::ActiveRecord::EventRepository,
      # so it never got SkipJsonSerialization mixed in as a side effect of #model_klasses.
      # This is what event_klass looks like in the relay's own process, which never calls
      # the repository at all.
      def untouched_event_klass
        Class.new(::ActiveRecord::Base) { self.table_name = "event_store_events" }
      end

      def insert_raw_event(event_klass, data:, metadata:)
        now = event_klass.connection.quote(Time.now.utc)
        event_klass.connection.execute(<<~SQL)
          INSERT INTO event_store_events (event_id, event_type, data, metadata, created_at, valid_at, published_at)
          VALUES (
            #{event_klass.connection.quote(SecureRandom.uuid)},
            'TestEvent',
            #{event_klass.connection.quote(data)},
            #{event_klass.connection.quote(metadata)},
            #{now}, #{now}, NULL
          )
        SQL
      end

      specify "deserializes data/metadata through the configured (non-NULL) serializer" do
        event_klass = untouched_event_klass
        insert_raw_event(event_klass, data: '{"foo":"bar"}', metadata: '{"correlation_id":"c1"}')
        client =
          helper.extended_client_class.new(
            repository: RubyEventStore::ActiveRecord::EventRepository.new(serializer: JSON),
            async_broker: RubyEventStore::Broker.new,
          )
        received = []
        client.async_broker.add_global_subscription(->(event) { received << event })
        relay = Relay.new(client: client, event_klass: event_klass, logger: Logger.new(File::NULL))

        processed = relay.process_batch

        expect(processed).to eq(1)
        expect(received.first.data).to eq({ "foo" => "bar" })
      end if %w[json jsonb].include?(ENV["DATA_TYPE"])

      specify "leaves data/metadata to ActiveRecord's own (de)serialization for a NULL serializer" do
        event_klass = untouched_event_klass
        insert_raw_event(event_klass, data: '{"foo":"bar"}', metadata: '{"correlation_id":"c1"}')
        client =
          helper.extended_client_class.new(
            repository: RubyEventStore::ActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL),
            async_broker: RubyEventStore::Broker.new,
          )
        received = []
        client.async_broker.add_global_subscription(->(event) { received << event })
        relay = Relay.new(client: client, event_klass: event_klass, logger: Logger.new(File::NULL))

        processed = relay.process_batch

        expect(processed).to eq(1)
        expect(received.first.data).to eq({ "foo" => "bar" })
      end if %w[json jsonb].include?(ENV["DATA_TYPE"])
    end
  end
end
