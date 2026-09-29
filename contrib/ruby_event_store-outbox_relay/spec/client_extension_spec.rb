# frozen_string_literal: true

require "spec_helper"
require "logger"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe ClientExtension do
      helper = SpecHelper.new

      around { |example| helper.run_lifecycle { example.run } }

      let(:client_class) { Class.new(Client) }
      let(:subscriptions) { helper.sync_subscriptions }
      let(:client) { client_class.new(repository: helper.repository, async_subscriptions: subscriptions) }

      describe "requiring the gem" do
        specify "changes no existing class, so a plain client stays plain" do
          expect(RubyEventStore::Client.ancestors).not_to include(ClientExtension)
          expect(RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)).not_to respond_to(:subscribe_async)
          expect(RubyEventStore::Client.instance_method(:publish).owner).to eq(RubyEventStore::Client)
        end

        specify "leaves the event repository alone" do
          expect(RubyEventStore::ActiveRecord::EventRepository.ancestors.first).to eq(RubyEventStore::ActiveRecord::EventRepository)
          expect(RubyEventStore::ActiveRecord::EventRepository.instance_method(:append_to_stream).owner).to eq(
            RubyEventStore::ActiveRecord::EventRepository,
          )
        end
      end

      describe "Client" do
        specify "is a RubyEventStore::Client with the extension" do
          expect(Client.superclass).to equal(RubyEventStore::Client)
          expect(Client.ancestors.first(2)).to eq([Client, ClientExtension])
        end
      end

      describe "including it into a client class" do
        specify "overrides the methods of RubyEventStore::Client, and only in that class" do
          klass = Class.new(RubyEventStore::Client) { include ClientExtension }

          expect(klass.instance_method(:publish).owner).to equal(ClientExtension)
          expect(RubyEventStore::Client.instance_method(:publish).owner).to equal(RubyEventStore::Client)
        end
      end

      describe "the RubyEventStore::Client internals it relies on" do
        specify "still exist, with the shape #publish expects" do
          parameters = ->(name) { RubyEventStore::Client.instance_method(name).parameters }

          expect(RubyEventStore::Client.private_instance_methods).to include(
            :enrich_events_metadata,
            :transform,
            :append_records_to_stream,
          )
          expect(parameters.call(:append_records_to_stream)).to eq(
            [[:req, :records], [:keyreq, :stream_name], [:keyreq, :expected_version]],
          )
          expect(parameters.call(:with_metadata)).to include([:req, :metadata_for_block])
          expect(RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new).instance_variables).to include(
            :@clock,
            :@broker,
            :@mapper,
            :@event_type_resolver,
          )
        end
      end

      describe "#publish" do
        specify "writes one outbox message per async subscriber, with the event, in one transaction" do
          client.subscribe_async(recording_handler("First"), to: [TestEvent])
          client.subscribe_async(recording_handler("Second"), to: [TestEvent])

          client.publish(event = TestEvent.new)

          expect(client.read.to_a.map(&:event_id)).to eq([event.event_id])
          expect(Message.order(:id).pluck(:event_id, :topic, :subscriber)).to eq(
            [[event.event_id, "TestEvent", "First"], [event.event_id, "TestEvent", "Second"]],
          )
        end

        specify "writes the messages due immediately" do
          client.subscribe_async(recording_handler("First"), to: [TestEvent])

          client.publish(TestEvent.new)

          message = Message.sole
          expect(message.next_attempt_at).to eq(message.created_at)
          expect(message.attempts).to eq(0)
        end

        specify "writes messages under the event's own type, even when the mapper rewrites the record's event type" do
          prefixing = Class.new do
            def dump(record)
              RubyEventStore::Record.new(**record.to_h, event_type: "Legacy::#{record.event_type}")
            end

            def load(record)
              RubyEventStore::Record.new(**record.to_h, event_type: record.event_type.delete_prefix("Legacy::"))
            end
          end
          mapper = RubyEventStore::Mappers::BatchMapper.new(
            RubyEventStore::Mappers::PipelineMapper.new(
              RubyEventStore::Mappers::Pipeline.new(prefixing.new, RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new),
            ),
          )
          client = client_class.new(repository: helper.repository, mapper: mapper, async_subscriptions: subscriptions)
          handler = recording_handler("OrderReport")
          client.subscribe_async(handler, to: [TestEvent])

          client.publish(event = TestEvent.new)

          expect(client.read.event(event.event_id)).to eq(event)
          expect(RubyEventStore::ActiveRecord.const_get(:Event).sole.event_type).to eq("Legacy::TestEvent")
          expect(Message.pluck(:topic, :subscriber)).to eq([%w[TestEvent OrderReport]])
          Relay.new(client: client, logger: Logger.new(File::NULL)).process_batch
          expect(handler.received.map(&:event_id)).to eq([event.event_id])
        end

        specify "makes the messages due at the real time, in UTC, whatever the client's clock says" do
          client.subscribe_async(recording_handler("First"), to: [TestEvent])
          allow(Time).to receive(:now) { Time.new(2026, 1, 1, 12, 0, 0, "+02:00") }
          allow(client.outbox).to receive(:append).and_call_original

          client.publish(TestEvent.new)

          expect(client.outbox).to have_received(:append).with(anything, hash_including(now: an_object_satisfying(&:utc?)))
          expect(Message.sole.next_attempt_at).to eq(Time.utc(2026, 1, 1, 10, 0, 0))
        end

        specify "writes no message for an event type without async subscribers" do
          client.subscribe_async(recording_handler("Other"), to: [AnotherTestEvent])

          client.publish(TestEvent.new)

          expect(Message.count).to eq(0)
        end

        specify "writes messages for each event of a batch, by its own type" do
          client.subscribe_async(recording_handler("First"), to: [TestEvent])
          client.subscribe_async(recording_handler("Other"), to: [AnotherTestEvent])

          client.publish([test_event = TestEvent.new, other_event = AnotherTestEvent.new])

          expect(Message.order(:id).pluck(:event_id, :subscriber)).to eq(
            [[test_event.event_id, "First"], [other_event.event_id, "Other"]],
          )
        end

        specify "writes messages under the given topic, and notifies sync subscribers of that topic" do
          sync = spy(:sync)
          client.subscribe_sync(sync, to: ["custom.topic"])
          client.subscribe_async(recording_handler("Custom"), to: ["custom.topic"])
          client.subscribe_async(recording_handler("Typed"), to: [TestEvent])

          client.publish(event = TestEvent.new, topic: "custom.topic")

          expect(Message.pluck(:topic, :subscriber)).to eq([%w[custom.topic Custom]])
          expect(sync).to have_received(:call).with(event)
        end

        specify "persists nothing, neither event nor messages, when the write fails" do
          client.subscribe_async(recording_handler("First"), to: [TestEvent])
          client.publish(TestEvent.new, stream_name: "s", expected_version: :none)

          expect do
            client.publish(TestEvent.new, stream_name: "s", expected_version: :none)
          end.to raise_error(RubyEventStore::WrongExpectedEventVersion)

          expect(client.read.count).to eq(1)
          expect(Message.count).to eq(1)
        end

        specify "rolls the event back when writing the messages fails" do
          client.subscribe_async(recording_handler("First"), to: [TestEvent])
          allow(Message).to receive(:insert_all!).and_raise(::ActiveRecord::StatementInvalid, "boom")

          expect { client.publish(TestEvent.new) }.to raise_error(::ActiveRecord::StatementInvalid)

          expect(client.read.count).to eq(0)
        end

        specify "does not notify sync subscribers when the write fails" do
          sync = spy(:sync)
          client.subscribe_sync(sync, to: [TestEvent])
          client.subscribe_async(recording_handler("First"), to: [TestEvent])
          allow(Message).to receive(:insert_all!).and_raise(::ActiveRecord::StatementInvalid, "boom")

          expect { client.publish(TestEvent.new) }.to raise_error(::ActiveRecord::StatementInvalid)

          expect(sync).not_to have_received(:call)
        end

        specify "notifies sync subscribers immediately, with the event, reproducing correlation and causation ids" do
          observed = nil
          client.subscribe_sync(->(_event) { observed = client.metadata.slice(:correlation_id, :causation_id) }, to: [TestEvent])

          client.publish(event = TestEvent.new)

          expect(observed).to eq(correlation_id: event.metadata[:correlation_id], causation_id: event.event_id)
          expect(client.metadata).to eq({})
        end

        specify "notifies sync subscribers only after the transaction committed" do
          transaction_open = nil
          client.subscribe_sync(->(_event) { transaction_open = Message.connection.transaction_open? }, to: [TestEvent])
          client.subscribe_async(recording_handler("First"), to: [TestEvent])

          client.publish(TestEvent.new)

          expect(transaction_open).to eq(false)
        end

        specify "does not deliver to async subscribers itself" do
          handler = recording_handler("First")
          client.subscribe_async(handler, to: [TestEvent])

          client.publish(TestEvent.new)

          expect(handler.received).to be_empty
        end

        specify "forwards stream_name and expected_version" do
          client.publish(TestEvent.new, stream_name: "custom-stream", expected_version: :none)

          expect(client.read.stream("custom-stream").count).to eq(1)
        end

        specify "falls back to a 2-arity broker, warning that topics are ignored" do
          calls = []
          broker = Object.new
          broker.define_singleton_method(:call) { |event, record| calls << [event, record] }
          client = client_class.new(repository: helper.repository, message_broker: broker, async_subscriptions: subscriptions)

          event = TestEvent.new

          expect { client.publish(event) }.to output(
            a_string_including("Message broker shall support topics").and(a_string_including("Topic WILL BE IGNORED")),
          ).to_stderr

          expect(calls.map { |e, _| e }).to eq([event])
          expect(calls.map { |_, record| record.event_id }).to eq([event.event_id])
        end

        specify "passes the topic, event and record to a 3-arity broker" do
          calls = []
          broker = Object.new
          broker.define_singleton_method(:call) { |topic, event, record| calls << [topic, event, record] }
          client = client_class.new(repository: helper.repository, message_broker: broker, async_subscriptions: subscriptions)
          event = TestEvent.new

          client.publish(event)

          expect(calls.map { |topic, e, record| [topic, e, record.event_id] }).to eq([["TestEvent", event, event.event_id]])
        end

        specify "returns the client" do
          expect(client.publish(TestEvent.new)).to equal(client)
        end
      end

      describe "#append" do
        specify "an append suspended in one fiber doesn't affect a publish in another fiber of the same thread" do
          repository = helper.repository
          suspending_repository = Object.new
          suspend_next = true
          suspending_repository.define_singleton_method(:append_to_stream) do |*args|
            was_suspending = suspend_next
            suspend_next = false
            Fiber.yield if was_suspending
            repository.append_to_stream(*args)
          end
          suspending_repository.define_singleton_method(:method_missing) { |name, *args, &block| repository.public_send(name, *args, &block) }
          suspending_repository.define_singleton_method(:respond_to_missing?) { |name, include_private| repository.respond_to?(name, include_private) }
          client = client_class.new(repository: suspending_repository, async_subscriptions: subscriptions)
          client.subscribe_async(recording_handler("First"), to: [TestEvent])
          appended, published = TestEvent.new, TestEvent.new

          appending = Fiber.new { client.append(appended) }
          appending.resume
          client.publish(published)
          appending.resume

          expect(client.read.count).to eq(2)
          expect(Message.pluck(:event_id)).to eq([published.event_id])
        end

        specify "persists the event without notifying anyone, and writes no message" do
          sync = spy(:sync)
          client.subscribe_sync(sync, to: [TestEvent])
          client.subscribe_async(recording_handler("First"), to: [TestEvent])

          client.append(event = TestEvent.new)

          expect(client.read.to_a.map(&:event_id)).to eq([event.event_id])
          expect(Message.count).to eq(0)
          expect(sync).not_to have_received(:call)
        end
      end

      describe "#subscribe_sync" do
        specify "has the same signature and behavior as #subscribe" do
          via_subscribe, via_subscribe_sync = spy(:via_subscribe), spy(:via_subscribe_sync)
          client.subscribe(via_subscribe, to: [TestEvent])
          client.subscribe_sync(via_subscribe_sync, to: [TestEvent])

          client.publish(event = TestEvent.new)

          expect(via_subscribe).to have_received(:call).with(event)
          expect(via_subscribe_sync).to have_received(:call).with(event)
        end

        specify "accepts a subscriber given only as a block" do
          received = []

          client.subscribe_sync(to: [TestEvent]) { |event| received << event }
          client.publish(event = TestEvent.new)

          expect(received).to eq([event])
        end
      end

      describe "#subscribe_async" do
        specify "registers the subscriber in async_subscriptions under the event type, not on the sync broker" do
          handler = recording_handler("First")

          client.subscribe_async(handler, to: [TestEvent])

          expect(subscriptions.resolve("TestEvent", "First")).to equal(handler)
          expect(client.subscribers_for(TestEvent)).to eq([])
        end

        specify "resolves event classes through the client's event type resolver" do
          client = client_class.new(repository: helper.repository, async_subscriptions: subscriptions, event_type_resolver: ->(klass) { "app.#{klass}" })

          client.subscribe_async(recording_handler("First"), to: [TestEvent])

          expect(subscriptions.names_for("app.TestEvent")).to eq(["First"])
        end

        specify "requires an explicit subscriber -- a block-only call raises" do
          expect { client.subscribe_async(to: [TestEvent]) { |_event| } }.to raise_error(ArgumentError)
        end

        specify "rejects an anonymous subscriber" do
          expect { client.subscribe_async(Class.new { def self.call(_) = nil }, to: [TestEvent]) }.to raise_error(ArgumentError, /named class/)
        end
      end

      describe "public readers" do
        specify "#mapper returns the configured mapper" do
          expect(client.mapper).to be_a(RubyEventStore::Mappers::BatchMapper)
        end

        specify "#async_subscriptions returns exactly the injected registry" do
          expect(client.async_subscriptions).to equal(subscriptions)
        end

        specify "#outbox returns exactly the injected outbox, and defaults to one on the outbox models" do
          outbox = Outbox.new

          expect(client_class.new(outbox: outbox).outbox).to equal(outbox)
          expect(client_class.new.outbox).to be_a(Outbox)
        end
      end

      describe "default async_subscriptions" do
        specify "dispatch through ActiveJobDispatcher with the YAML serializer" do
          TestAsyncJob.reset!
          client = client_class.new(repository: helper.repository)
          client.subscribe_async(TestAsyncJob, to: [TestEvent])
          event = TestEvent.new
          client.publish(event)
          record = client.mapper.events_to_records([event]).first

          client.async_subscriptions.dispatch(TestAsyncJob, event, record)

          expect(TestAsyncJob.received.first).to eq(record.serialize(RubyEventStore::Serializers::YAML).to_h.transform_keys(&:to_s))
        end

        specify "serialize with exactly RubyEventStore::Serializers::YAML" do
          dispatcher = client_class.new.async_subscriptions.send(:dispatcher)

          expect(dispatcher).to be_an_instance_of(ActiveJobDispatcher)
          expect(dispatcher.send(:serializer)).to equal(RubyEventStore::Serializers::YAML)
        end

        specify "reject subscribers that are not ActiveJob classes" do
          expect { client_class.new.subscribe_async(recording_handler("NotAJob"), to: [TestEvent]) }.to raise_error(
            RubyEventStore::InvalidHandler,
          )
        end
      end
    end
  end
end
