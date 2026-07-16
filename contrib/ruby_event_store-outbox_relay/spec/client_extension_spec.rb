# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe ClientExtension do
      let(:client_class) { Class.new(RubyEventStore::Client) }
      let(:calls) { [] }
      let(:repository) do
        recorded_calls = calls
        Object.new.tap do |repo|
          repo.define_singleton_method(:append_to_stream) do |records, stream, expected_version|
            recorded_calls << { records: records, stream: stream, expected_version: expected_version }
          end
        end
      end

      specify "is included onto RubyEventStore::Client at gem-load time, so every client is extended" do
        expect(RubyEventStore::Client.ancestors).to include(ClientExtension::InstanceMethods)
      end

      describe ".included" do
        specify "prepends InstanceMethods, so its methods override the including class's own" do
          klass = Class.new

          klass.include(ClientExtension)

          expect(klass.ancestors.first).to eq(ClientExtension::InstanceMethods)
        end
      end

      specify "publish forwards records/stream/expected_version to the repository unchanged (#publish is not overridden)" do
        client = client_class.new(repository: repository, async_broker: double(:async_broker))

        result = client.publish(event = TestEvent.new)

        expect(result).to eq(client)
        expect(calls.size).to eq(1)
        expect(calls.first[:records].map(&:event_id)).to eq([event.event_id])
        expect(calls.first[:records].first).to be_a(RubyEventStore::Record)
        expect(calls.first[:stream]).to eq(Stream.new(GLOBAL_STREAM))
        expect(calls.first[:expected_version]).to eq(ExpectedVersion.any)
      end

      specify "publish always dispatches synchronously through the sync broker (#publish is not overridden)" do
        handler = spy(:handler)
        client = client_class.new(repository: repository, async_broker: double(:async_broker))
        client.subscribe(handler, to: [TestEvent])

        client.publish(event = TestEvent.new)

        expect(handler).to have_received(:call).with(event)
      end

      specify "publish forwards topic, stream_name, and expected_version, exactly like the original publish" do
        SpecHelper.new.run_lifecycle do
          client =
            client_class.new(
              repository: RubyEventStore::ActiveRecord::EventRepository.new(serializer: RubyEventStore::Serializers::YAML),
              async_broker: double(:async_broker),
            )
          handler = spy(:handler)
          client.subscribe_sync(handler, to: ["CustomTopic"])

          event = TestEvent.new
          client.publish(event, topic: "CustomTopic", stream_name: "custom-stream", expected_version: :none)

          expect(handler).to have_received(:call).with(event)
          expect(client.read.stream("custom-stream").to_a.map(&:event_id)).to eq([event.event_id])
          expect do
            client.publish(TestEvent.new, stream_name: "custom-stream", expected_version: :none)
          end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
        end
      end

      describe "#subscribe_sync" do
        specify "has the same signature and behavior as #subscribe (kept as a working alias)" do
          client = client_class.new(repository: repository, async_broker: double(:async_broker))
          via_subscribe = spy(:via_subscribe)
          via_subscribe_sync = spy(:via_subscribe_sync)
          client.subscribe(via_subscribe, to: [TestEvent])
          client.subscribe_sync(via_subscribe_sync, to: [TestEvent])

          client.publish(event = TestEvent.new)

          expect(via_subscribe).to have_received(:call).with(event)
          expect(via_subscribe_sync).to have_received(:call).with(event)
        end

        specify "still supports Within (temporary subscriptions), unchanged" do
          client = client_class.new(repository: repository, async_broker: double(:async_broker))
          received = []

          client.within { client.publish(TestEvent.new) }.subscribe(->(event) { received << event }, to: [TestEvent]).call

          expect(received.size).to eq(1)
        end

        specify "accepts a subscriber given only as a block" do
          client = client_class.new(repository: repository, async_broker: double(:async_broker))
          received = []

          client.subscribe_sync(to: [TestEvent]) { |event| received << event }
          client.publish(event = TestEvent.new)

          expect(received).to eq([event])
        end
      end

      describe "#subscribe_async" do
        specify "does not deliver synchronously during publish" do
          client = client_class.new(repository: repository, async_broker: RubyEventStore::Broker.new)
          handler = spy(:handler)
          client.subscribe_async(handler, to: [TestEvent])

          client.publish(TestEvent.new)

          expect(handler).not_to have_received(:call)
        end

        specify "registers the subscriber on async_broker, not on the sync broker" do
          async_broker = RubyEventStore::Broker.new
          client = client_class.new(async_broker: async_broker)
          handler = spy(:handler)

          client.subscribe_async(handler, to: [TestEvent])

          event = TestEvent.new
          async_broker.call(event.event_type, event, double(:record))
          expect(handler).to have_received(:call).with(event)
        end

        specify "requires an explicit subscriber -- a block-only call raises (blocks are not serializable)" do
          client = client_class.new(async_broker: double(:async_broker))

          expect { client.subscribe_async(to: [TestEvent]) { |_event| } }.to raise_error(ArgumentError)
        end
      end

      describe "public readers" do
        specify "#repository returns exactly the configured repository" do
          client = client_class.new(repository: repository, async_broker: double(:async_broker))
          expect(client.repository).to equal(repository)
        end

        specify "#mapper returns the configured (batch-wrapped) mapper" do
          client = client_class.new(async_broker: double(:async_broker))
          expect(client.mapper).to be_a(RubyEventStore::Mappers::BatchMapper)
        end

        specify "#async_broker returns exactly the injected broker" do
          async_broker = double(:async_broker)
          client = client_class.new(async_broker: async_broker)
          expect(client.async_broker).to equal(async_broker)
        end
      end

      describe "default async_broker" do
        specify "dispatches through RailsEventStore::ActiveJobScheduler using the repository's serializer" do
          TestAsyncJob.reset!
          SpecHelper.new.run_lifecycle do
            repository = RubyEventStore::ActiveRecord::EventRepository.new(serializer: RubyEventStore::Serializers::YAML)
            client = client_class.new(repository: repository)
            client.subscribe_async(TestAsyncJob, to: [TestEvent])
            event_klass = RubyEventStore::ActiveRecord::WithDefaultModels.new.call.first
            relay = Relay.new(client: client, event_klass: event_klass)

            event = TestEvent.new
            client.publish(event)
            relay.process_batch

            expect(TestAsyncJob.received.size).to eq(1)
            expect(TestAsyncJob.received.first["event_id"]).to eq(event.event_id)
          end
        end
      end

      describe "RailsEventStore::Client" do
        specify "is extended too -- gains subscribe_sync/subscribe_async/async_broker" do
          expect(RailsEventStore::Client.ancestors).to include(ClientExtension::InstanceMethods)
        end

        specify "honors a custom async_broker:, even though RailsEventStore::Client's own #initialize has a fixed keyword list that never forwards it" do
          SpecHelper.new.run_lifecycle do
            custom_async_broker = RubyEventStore::Broker.new
            client = RailsEventStore::Client.new(async_broker: custom_async_broker)

            expect(client.async_broker).to equal(custom_async_broker)
          end
        end

        specify "still builds the default async_broker when none is given" do
          SpecHelper.new.run_lifecycle { expect(RailsEventStore::Client.new.async_broker).to be_a(RubyEventStore::Broker) }
        end
      end
    end
  end
end
