require 'spec_helper'
require 'time'

module RubyEventStore
  RSpec.describe Client do
    TestEvent = Class.new(RubyEventStore::Event)

    specify 'publish_event returns :ok when success' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect(client.publish_event(TestEvent.new)).to eq(:ok)
    end

    specify 'append_to_stream returns :ok when success' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect(client.append_to_stream(TestEvent.new, stream_name: stream)).to eq(:ok)
    end

    specify 'append to default stream when not specified' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      test_event = TestEvent.new
      expect(client.append_to_stream(test_event)).to eq(:ok)
      expect(client.read_stream_events_forward(GLOBAL_STREAM)).to eq([test_event])
    end

    specify 'delete_stream returns :ok when success' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect(client.delete_stream(stream)).to eq(:ok)
    end

    specify 'PubSub::Broker is a default event broker' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect(client.send("event_broker")).to be_a(RubyEventStore::PubSub::Broker)
    end

    specify 'setup event broker dependency' do
      broker = RubyEventStore::PubSub::Broker.new
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new, event_broker: broker)
      expect(client.send("event_broker")).to eql(broker)
    end

    specify 'publish to default stream when not specified' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      test_event = TestEvent.new
      expect(client.publish_event(test_event)).to eq(:ok)
      expect(client.read_stream_events_forward(GLOBAL_STREAM)).to eq([test_event])
    end

    specify 'publish first event, expect any stream state' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event   = TestEvent.new
      expect(client.publish_event(first_event, stream_name: stream)).to eq(:ok)
      expect(client.read_stream_events_forward(stream)).to eq([first_event])
    end

    specify 'publish next event, expect any stream state' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event   = TestEvent.new
      second_event  = TestEvent.new
      client.append_to_stream(first_event, stream_name: stream)
      expect(client.publish_event(second_event, stream_name: stream)).to eq(:ok)
      expect(client.read_stream_events_forward(stream)).to eq([first_event, second_event])
    end

    specify 'publish first event, expect empty stream' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event   = TestEvent.new
      expect(client.publish_event(first_event, stream_name: stream, expected_version: :none)).to eq(:ok)
      expect(client.read_stream_events_forward(stream)).to eq([first_event])
    end

    specify 'publish first event, fail if not empty stream' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event   = TestEvent.new
      second_event  = TestEvent.new
      client.append_to_stream(first_event, stream_name: stream)
      expect{ client.publish_event(second_event, stream_name: stream, expected_version: :none) }.to raise_error(WrongExpectedEventVersion)
      expect(client.read_stream_events_forward(stream)).to eq([first_event])
    end

    specify 'publish event, expect last event to be the last read one' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event   = TestEvent.new
      second_event  = TestEvent.new
      client.append_to_stream(first_event, stream_name: stream)
      expect(client.publish_event(second_event, stream_name: stream, expected_version: 0)).to eq(:ok)
      expect(client.read_stream_events_forward(stream)).to eq([first_event, second_event])
    end

    specify 'publish event, fail if last event is not the last read one' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event   = TestEvent.new
      second_event  = TestEvent.new
      third_event   = TestEvent.new
      client.append_to_stream(first_event, stream_name: stream)
      client.append_to_stream(second_event, stream_name: stream)
      expect{ client.publish_event(third_event, stream_name: stream, expected_version: first_event.event_id) }.to raise_error(WrongExpectedEventVersion)
      expect(client.read_stream_events_forward(stream)).to eq([first_event, second_event])
    end

    specify 'append many events' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event   = TestEvent.new
      second_event  = TestEvent.new
      client.append_to_stream([first_event, second_event], stream_name: stream, expected_version: -1)
      expect(client.read_stream_events_forward(stream)).to eq([first_event, second_event])
    end

    specify 'read only up to page size from stream' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      (1..102).each { client.append_to_stream(TestEvent.new, stream_name: stream) }
      expect(client.read_events_forward(stream, count: 10).size).to eq(10)
      expect(client.read_events_backward(stream, count: 10).size).to eq(10)
      expect(client.read_events_forward(stream).size).to eq(PAGE_SIZE)
      expect(client.read_events_backward(stream).size).to eq(PAGE_SIZE)

      expect(client.read_all_streams_forward(count: 10).size).to eq(10)
      expect(client.read_all_streams_backward(count: 10).size).to eq(10)
      expect(client.read_all_streams_forward.size).to eq(PAGE_SIZE)
      expect(client.read_all_streams_backward.size).to eq(PAGE_SIZE)
    end

    specify 'published event metadata will be enriched by proc execution' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new, metadata_proc: ->{ {request_id: '127.0.0.1'} })
      event = TestEvent.new
      client.publish_event(event)
      published = client.read_all_streams_forward
      expect(published.size).to eq(1)
      expect(published.first.metadata[:request_id]).to eq('127.0.0.1')
      expect(published.first.metadata[:timestamp]).to be_a Time
    end

    specify 'only timestamp set inn metadata when event stored in stream if metadata proc return nil' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new, metadata_proc: ->{ nil })
      event = TestEvent.new
      client.append_to_stream(event)
      published = client.read_all_streams_forward
      expect(published.size).to eq(1)
      expect(published.first.metadata.keys).to eq([:timestamp])
      expect(published.first.metadata[:timestamp]).to be_a Time
    end

    specify 'timestamp is utc time' do
      now = Time.parse('2015-05-04 15:17:11 +0200')
      utc = Time.parse('2015-05-04 13:17:23 UTC')
      allow_any_instance_of(Time).to receive(:now).and_return(now)
      allow_any_instance_of(Time).to receive(:utc).and_return(utc)
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      event = TestEvent.new
      client.publish_event(event)
      published = client.read_all_streams_forward
      expect(published.size).to eq(1)
      expect(published.first.metadata[:timestamp]).to eq(utc)
    end
  end
end
