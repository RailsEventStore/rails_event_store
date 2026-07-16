# frozen_string_literal: true

require "spec_helper"
require "logger"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe Relay do
      let(:client_class) { Class.new(RubyEventStore::Client) }

      def build_relay(client: double(:client), **overrides)
        Relay.new(client: client, event_klass: double(:event_klass), **overrides)
      end

      describe "#initialize" do
        specify "stores every given collaborator and setting in its own instance variable" do
          client = double(:client)
          event_klass = double(:event_klass)
          logger = double(:logger)

          relay = Relay.new(client: client, event_klass: event_klass, batch_size: 42, poll_interval: 7, logger: logger)

          expect(relay.instance_variable_get(:@client)).to equal(client)
          expect(relay.instance_variable_get(:@event_klass)).to equal(event_klass)
          expect(relay.instance_variable_get(:@batch_size)).to eq(42)
          expect(relay.instance_variable_get(:@poll_interval)).to eq(7)
          expect(relay.instance_variable_get(:@logger)).to equal(logger)
          expect(relay.instance_variable_get(:@shutting_down)).to eq(false)
        end

        specify "defaults batch_size, poll_interval, and logger when not given" do
          relay = build_relay

          expect(relay.instance_variable_get(:@batch_size)).to eq(100)
          expect(relay.instance_variable_get(:@poll_interval)).to eq(1)
          logger = relay.instance_variable_get(:@logger)
          expect(logger).to be_a(Logger)
          expect(logger.instance_variable_get(:@logdev).dev).to equal($stdout)
        end

        specify "defaults event_klass to the real ActiveRecord::Event model" do
          relay = Relay.new(client: double(:client))

          expect(relay.instance_variable_get(:@event_klass)).to equal(RubyEventStore::ActiveRecord.const_get(:Event))
        end
      end

      describe "#fetch_batch (private)" do
        def scope_double
          double(:scope)
        end

        specify "queries published_at: nil ordered by id, limited to batch_size, and applies the lock when present" do
          calls = []
          final_scope = scope_double
          ordered_scope = scope_double
          limited_scope = scope_double
          event_klass = double(:event_klass)
          allow(event_klass).to receive(:where) { |*a| calls << [:where, a]; ordered_scope }
          allow(ordered_scope).to receive(:order) { |*a| calls << [:order, a]; limited_scope }
          allow(limited_scope).to receive(:limit) { |*a| calls << [:limit, a]; final_scope }
          allow(final_scope).to receive(:lock) { |*a| calls << [:lock, a]; final_scope }
          allow(final_scope).to receive(:to_a) { calls << [:to_a]; [] }
          allow(event_klass).to receive(:connection).and_return(double(:connection, adapter_name: "PostgreSQL"))

          relay = Relay.new(client: double(:client), event_klass: event_klass, batch_size: 55)
          result = relay.send(:fetch_batch)

          expect(calls).to eq(
            [
              [:where, [{ published_at: nil }]],
              [:order, [:id]],
              [:limit, [55]],
              [:lock, ["FOR UPDATE SKIP LOCKED"]],
              [:to_a],
            ],
          )
          expect(result).to eq([])
        end

        specify "does not lock when the adapter provides no lock_clause (e.g. SQLite)" do
          calls = []
          final_scope = scope_double
          ordered_scope = scope_double
          limited_scope = scope_double
          event_klass = double(:event_klass)
          allow(event_klass).to receive(:where) { |*a| calls << [:where, a]; ordered_scope }
          allow(ordered_scope).to receive(:order) { |*a| calls << [:order, a]; limited_scope }
          allow(limited_scope).to receive(:limit) { |*a| calls << [:limit, a]; final_scope }
          allow(final_scope).to receive(:lock) { |*a| calls << [:lock, a]; final_scope }
          allow(final_scope).to receive(:to_a) { calls << [:to_a]; [] }
          allow(event_klass).to receive(:connection).and_return(double(:connection, adapter_name: "SQLite"))

          relay = Relay.new(client: double(:client), event_klass: event_klass, batch_size: 55)
          result = relay.send(:fetch_batch)

          expect(calls).to eq([[:where, [{ published_at: nil }]], [:order, [:id]], [:limit, [55]], [:to_a]])
          expect(result).to eq([])
        end
      end

      describe "#dispatch (private)" do
        specify "calls a 3-arity broker with exactly the event's own type, the event, and the record" do
          calls = []
          async_broker = Object.new
          async_broker.define_singleton_method(:call) { |topic, event, record| calls << [topic, event, record] }
          client = client_class.new(async_broker: async_broker)
          relay = build_relay(client: client)
          event = TestEvent.new(metadata: { correlation_id: SecureRandom.uuid })
          record = double(:record)

          relay.send(:dispatch, event, record)

          expect(calls).to eq([[event.event_type, event, record]])
        end

        specify "falls back to a 2-arity broker.call and warns when the broker doesn't support topics" do
          calls = []
          async_broker = Object.new
          async_broker.define_singleton_method(:call) { |event, record| calls << [event, record] }
          client = client_class.new(async_broker: async_broker)
          relay = build_relay(client: client)
          event = TestEvent.new(metadata: { correlation_id: SecureRandom.uuid })
          record = double(:record)

          expect { relay.send(:dispatch, event, record) }.to output(
            a_string_including("Message broker shall support topics")
              .and(a_string_including("Topic WILL BE IGNORED in the current broker"))
              .and(a_string_including("Modify the broker implementation to pass topic as an argument to broker.call method")),
          ).to_stderr

          expect(calls).to eq([[event, record]])
        end

        specify "reproduces correlation_id/causation_id via client.with_metadata around the broker call" do
          observed = {}
          async_broker = Object.new
          client = client_class.new(async_broker: async_broker)
          async_broker.define_singleton_method(:call) do |_topic, _event, _record|
            observed[:correlation_id] = client.metadata[:correlation_id]
            observed[:causation_id] = client.metadata[:causation_id]
          end
          relay = build_relay(client: client)
          correlation_id = SecureRandom.uuid
          event = TestEvent.new(metadata: { correlation_id: correlation_id })

          relay.send(:dispatch, event, double(:record))

          expect(observed[:correlation_id]).to eq(correlation_id)
          expect(observed[:causation_id]).to eq(event.event_id)
          expect(client.metadata).to eq({})
        end
      end

      describe "#to_record (private)" do
        def build_relay_with_serializer(serializer)
          repository = double(:repository, serializer: serializer)
          client = client_class.new(repository: repository, async_broker: double(:async_broker))
          build_relay(client: client)
        end

        specify "preserves microsecond precision and honors row.valid_at when present" do
          relay = build_relay_with_serializer(RubyEventStore::Serializers::YAML)
          row =
            double(
              :row,
              event_id: SecureRandom.uuid,
              metadata: RubyEventStore::Serializers::YAML.dump({}),
              data: RubyEventStore::Serializers::YAML.dump({}),
              event_type: "TestEvent",
              created_at: Time.utc(2026, 1, 1, 0, 0, 0, 123_456),
              valid_at: Time.utc(2026, 2, 2, 0, 0, 0, 654_321),
            )

          record = relay.send(:to_record, row)

          expect(record.timestamp).to eq(Time.utc(2026, 1, 1, 0, 0, 0, 123_456))
          expect(record.valid_at).to eq(Time.utc(2026, 2, 2, 0, 0, 0, 654_321))
        end

        specify "falls back to row.created_at when row.valid_at is nil" do
          relay = build_relay_with_serializer(RubyEventStore::Serializers::YAML)
          row =
            double(
              :row,
              event_id: SecureRandom.uuid,
              metadata: RubyEventStore::Serializers::YAML.dump({}),
              data: RubyEventStore::Serializers::YAML.dump({}),
              event_type: "TestEvent",
              created_at: Time.utc(2026, 1, 1, 0, 0, 0, 123_456),
              valid_at: nil,
            )

          record = relay.send(:to_record, row)

          expect(record.valid_at).to eq(Time.utc(2026, 1, 1, 0, 0, 0, 123_456))
        end
      end

      describe "#run" do
        specify "installs signal handlers, logs start/stop, and loops until shutting down, sleeping only on empty batches" do
          logger = double(:logger, info: nil)
          relay = build_relay(poll_interval: 99, logger: logger)
          allow(relay).to receive(:install_signal_handlers)
          allow(relay).to receive(:sleep)
          call_count = 0
          allow(relay).to receive(:process_batch_safely) do
            call_count += 1
            relay.instance_variable_set(:@shutting_down, true) if call_count == 3
            call_count == 3 ? 5 : 0
          end

          relay.run

          expect(relay).to have_received(:install_signal_handlers)
          expect(logger).to have_received(:info).with("Starting RubyEventStore::OutboxRelay")
          expect(logger).to have_received(:info).with("Gracefully shutting down")
          expect(relay).to have_received(:process_batch_safely).exactly(3).times
          expect(relay).to have_received(:sleep).with(99).twice
        end
      end
    end
  end
end
