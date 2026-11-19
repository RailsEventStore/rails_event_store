# frozen_string_literal: true

require "spec_helper"
require "active_support/core_ext/object/try"
require "active_support/isolated_execution_state"
require "active_support/notifications"

module RubyEventStore
  ::RSpec.describe Client do
    let(:client) { Client.new(repository: StreamMetadataAwareRepository.new(InMemoryRepository.new)) }

    specify "stream metadata needs StreamMetadataAwareRepository" do
      client = Client.new(repository: InMemoryRepository.new)

      expect { client.set_stream_metadata("some", max_count: 1) }.to raise_error(StreamMetadataNotSupported)
      expect { client.stream_metadata("some") }.to raise_error(StreamMetadataNotSupported)
      expect { client.truncate_stream("some", before: 1) }.to raise_error(StreamMetadataNotSupported)
      expect { client.soft_delete_stream("some") }.to raise_error(StreamMetadataNotSupported)
      expect { client.restore_stream("some") }.to raise_error(StreamMetadataNotSupported)
      expect { client.tombstone_stream("some") }.to raise_error(StreamMetadataNotSupported)
    end

    specify "works through instrumented repository" do
      client =
        Client.new(
          repository:
            InstrumentedRepository.new(
              StreamMetadataAwareRepository.new(InMemoryRepository.new),
              ActiveSupport::Notifications,
            ),
        )

      client.set_stream_metadata("some", max_age: 60)

      expect(client.stream_metadata("some")).to eq(StreamMetadata.none.with(max_age: 60))
    end

    specify "sets retention" do
      expect(client.set_stream_metadata("some", max_count: 10, max_age: 60)).to be(client)
      expect(client.stream_metadata("some")).to eq(StreamMetadata.none.with(max_count: 10, max_age: 60))

      client.set_stream_metadata("some", max_count: 5)
      expect(client.stream_metadata("some")).to eq(StreamMetadata.none.with(max_count: 5))

      client.set_stream_metadata("some", max_age: 30)
      expect(client.stream_metadata("some")).to eq(StreamMetadata.none.with(max_age: 30))
    end

    specify "truncates" do
      client.append(events = [TestEvent.new, TestEvent.new, TestEvent.new], stream_name: "some", expected_version: :auto)

      expect(client.truncate_stream("some", before: 2)).to be(client)

      expect(client.read.stream("some").to_a).to eq(events.drop(2))
      expect(client.stream_metadata("some").truncate_before).to eq(2)
      expect(client.read.to_a).to start_with(events)
    end

    specify "soft deletes" do
      client.append([TestEvent.new, TestEvent.new], stream_name: "some", expected_version: :auto)

      expect(client.soft_delete_stream("some")).to be(client)

      expect(client.read.stream("some").to_a).to be_empty
      expect(client.stream_metadata("some")).to have_attributes(soft_deleted?: true, truncate_before: 2)
    end

    specify "restores" do
      client.append(events = [TestEvent.new, TestEvent.new], stream_name: "some", expected_version: :auto)
      client.soft_delete_stream("some")

      expect(client.restore_stream("some")).to eq(
        StreamMetadataAwareRepository::StreamRestore.new(restored: 2, missing: 0),
      )
      expect(client.read.stream("some").to_a).to eq(events)
    end

    specify "tombstones" do
      client.append(event = TestEvent.new, stream_name: "some", expected_version: :auto)

      expect(client.tombstone_stream("some")).to be(client)

      expect(client.stream_metadata("some")).to be_tombstoned
      expect(client.read.stream("some").to_a).to eq([event])
      expect { client.publish(TestEvent.new, stream_name: "some", expected_version: :auto) }.to raise_error(
        StreamTombstoned,
      )
    end

    specify "refuses to delete a tombstoned stream" do
      client.append(event = TestEvent.new, stream_name: "some", expected_version: :auto)
      client.tombstone_stream("some")

      expect { client.delete_stream("some") }.to raise_error(StreamTombstoned)
      expect(client.read.stream("some").to_a).to eq([event])
    end

    specify "deletes a stream of a plain repository with the stream only" do
      repository = InMemoryRepository.new
      client = Client.new(repository: repository)
      expect(repository).to receive(:delete_stream).with(Stream.new("some")).and_call_original

      expect(client.delete_stream("some")).to be(client)
    end

    specify "deletes a stream through instrumented StreamMetadataAwareRepository" do
      client =
        Client.new(
          repository:
            InstrumentedRepository.new(
              StreamMetadataAwareRepository.new(InMemoryRepository.new, publish_metadata_events: true),
              ActiveSupport::Notifications,
            ),
        )
      handled = []
      client.subscribe(to: [StreamMetadataEvents::StreamRestored]) { |event| handled << event }
      client.soft_delete_stream("some")

      expect(client.delete_stream("some")).to be(client)
      expect(handled.size).to eq(1)
    end

    specify "passes expected version of the stream" do
      client.append([TestEvent.new, TestEvent.new], stream_name: "some", expected_version: :auto)

      expect { client.set_stream_metadata("some", max_count: 1, expected_version: 0) }.to raise_error(
        WrongExpectedEventVersion,
      )
      expect { client.truncate_stream("some", before: 1, expected_version: :none) }.to raise_error(
        WrongExpectedEventVersion,
      )
      expect { client.soft_delete_stream("some", expected_version: 0) }.to raise_error(WrongExpectedEventVersion)
      expect { client.restore_stream("some", expected_version: 0) }.to raise_error(WrongExpectedEventVersion)
      expect { client.tombstone_stream("some", expected_version: 0) }.to raise_error(WrongExpectedEventVersion)
      expect(client.read.stream("$$some").to_a).to be_empty

      client.set_stream_metadata("some", max_count: 1, expected_version: 1)
      client.truncate_stream("some", before: 1, expected_version: 1)
      client.soft_delete_stream("some", expected_version: 1)
      client.restore_stream("some", expected_version: 1)
      client.tombstone_stream("some", expected_version: 1)
      expect(client.read.stream("$$some").count).to eq(5)
    end

    describe "metadata events" do
      let(:client) do
        Client.new(
          repository: StreamMetadataAwareRepository.new(InMemoryRepository.new, publish_metadata_events: true),
        )
      end
      let(:handled) { [] }

      def handle(client, event_class, &block)
        client.subscribe(to: [event_class]) do |event|
          handled << event
          block&.call(event)
        end
      end

      specify "are not handed to subscribers by default" do
        client = Client.new(repository: StreamMetadataAwareRepository.new(InMemoryRepository.new))
        client.subscribe_to_all_events { |event| handled << event }
        client.append(TestEvent.new, stream_name: "some", expected_version: :auto)

        client.set_stream_metadata("some", max_count: 1)
        client.truncate_stream("some", before: 1)
        client.soft_delete_stream("some")
        client.restore_stream("some")
        client.tombstone_stream("some")

        expect(handled).to be_empty
        expect(client.read.stream("$$some").count).to eq(5)
      end

      specify "are handed to subscribers of their type when the operation is complete" do
        client.append([TestEvent.new, last = TestEvent.new], stream_name: "some", expected_version: :auto)
        handle(client, StreamMetadataEvents::StreamMetadataChanged)
        handle(client, StreamMetadataEvents::StreamTruncated) do
          expect(client.read.stream("some").to_a).to eq([last])
        end
        handle(client, StreamMetadataEvents::StreamSoftDeleted) do
          expect(client.read.stream("some").to_a).to be_empty
        end
        handle(client, StreamMetadataEvents::StreamRestored) do
          expect(client.read.stream("some").count).to eq(2)
        end
        handle(client, StreamMetadataEvents::StreamTombstoned) do
          expect(client.stream_metadata("some")).to be_tombstoned
        end

        client.set_stream_metadata("some", max_count: 1)
        client.truncate_stream("some", before: 1)
        client.soft_delete_stream("some")
        client.restore_stream("some")
        client.tombstone_stream("some")

        expect(handled).to eq(client.read.stream("$$some").to_a)
        expect(handled.map(&:class)).to eq(
          [
            StreamMetadataEvents::StreamMetadataChanged,
            StreamMetadataEvents::StreamTruncated,
            StreamMetadataEvents::StreamSoftDeleted,
            StreamMetadataEvents::StreamRestored,
            StreamMetadataEvents::StreamTombstoned,
          ],
        )
        expect(handled.map { |event| event.data.fetch("stream") }.uniq).to eq(["some"])
      end

      specify "cause what their handlers publish" do
        handle(client, StreamMetadataEvents::StreamTombstoned) do
          client.publish(TestEvent.new, stream_name: "audit")
        end

        client.tombstone_stream("some")

        expect(client.read.stream("audit").first.metadata[:causation_id]).to eq(handled.first.event_id)
      end

      specify "carry metadata enriched as for publish" do
        time = Time.utc(2026, 11, 18, 12, 0, 0)
        client =
          Client.new(
            repository: StreamMetadataAwareRepository.new(InMemoryRepository.new, publish_metadata_events: true),
            clock: -> { time },
            correlation_id_generator: -> { "correlation" },
          )
        client.subscribe_to_all_events { |event| handled << event }
        client.append(TestEvent.new, stream_name: "some", expected_version: :auto)
        handled.clear

        client.with_metadata(request_id: "request", remote_ip: "ip") do
          client.set_stream_metadata("some", max_count: 1)
          client.truncate_stream("some", before: 1)
          client.soft_delete_stream("some")
          client.restore_stream("some")
          client.tombstone_stream("some")
        end

        expect(handled.size).to eq(5)
        expected = { request_id: "request", remote_ip: "ip", correlation_id: "correlation", timestamp: time, valid_at: time }
        handled.each { |event| expect(event.metadata.to_h).to eq(expected) }
        client.read.stream("$$some").each { |event| expect(event.metadata.to_h).to eq(expected) }
      end

      specify "take correlation, timestamp and validity from with_metadata" do
        timestamp = Time.utc(2026, 1, 1)
        valid_at = Time.utc(2025, 1, 1)
        client.subscribe_to_all_events { |event| handled << event }

        client.with_metadata(correlation_id: "given", timestamp: timestamp, valid_at: valid_at) do
          client.tombstone_stream("some")
        end

        expect(handled.first.metadata.to_h).to eq(correlation_id: "given", timestamp: timestamp, valid_at: valid_at)
      end

      specify "get a new correlation and the current time outside with_metadata" do
        client.subscribe_to_all_events { |event| handled << event }

        client.tombstone_stream("some")
        client.tombstone_stream("other")

        expect(handled.map { |event| event.metadata[:correlation_id] }.uniq.size).to eq(2)
        expect(handled.first.metadata[:timestamp]).to be_within(5).of(Time.now.utc)
        expect(handled.first.metadata[:valid_at]).to eq(handled.first.metadata[:timestamp])
      end

      specify "are stored enriched and not published with the option off" do
        client = Client.new(repository: StreamMetadataAwareRepository.new(InMemoryRepository.new))
        client.subscribe_to_all_events { |event| handled << event }

        client.with_metadata(request_id: "request") { client.tombstone_stream("some") }

        expect(handled).to be_empty
        expect(client.read.stream("$$some").first.metadata.to_h).to include(request_id: "request", correlation_id: String)
      end

      specify "include StreamRestored written by delete_stream" do
        client.subscribe_to_all_events { |event| handled << event }
        client.append(TestEvent.new, stream_name: "some", expected_version: :auto)
        client.soft_delete_stream("some")
        handled.clear

        client.with_metadata(request_id: "request") { client.delete_stream("some") }

        expect(handled.map(&:class)).to eq([StreamMetadataEvents::StreamRestored])
        expect(handled.first.metadata.to_h).to include(request_id: "request", correlation_id: String, timestamp: Time)
        expect(client.read.stream("$$some").to_a.last).to eq(handled.first)
        expect(client.read.stream("$$some").to_a.last.metadata[:request_id]).to eq("request")
      end

      specify "store StreamRestored of delete_stream enriched without publishing it with the option off" do
        client = Client.new(repository: StreamMetadataAwareRepository.new(InMemoryRepository.new))
        client.subscribe_to_all_events { |event| handled << event }
        client.soft_delete_stream("some")

        client.with_metadata(request_id: "request") { client.delete_stream("some") }

        expect(handled).to be_empty
        expect(client.read.stream("$$some").to_a.last.metadata.to_h).to include(request_id: "request")
      end

      specify "go to a broker without topics" do
        broker =
          Class.new do
            def initialize
              @calls = []
            end

            attr_reader :calls

            def call(event, record)
              @calls << [event, record]
            end
          end.new
        client =
          Client.new(
            repository: StreamMetadataAwareRepository.new(InMemoryRepository.new, publish_metadata_events: true),
            message_broker: broker,
          )

        expect { client.tombstone_stream("some") }.to output(/Message broker shall support topics/).to_stderr

        event, record = broker.calls.first
        expect(event).to be_a(StreamMetadataEvents::StreamTombstoned)
        expect(record.event_id).to eq(event.event_id)
      end
    end
  end
end
