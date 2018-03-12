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

    specify 'publish to default stream when not specified' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      test_event = TestEvent.new
      expect(client.publish_events([test_event])).to eq(:ok)
      expect(client.read_stream_events_forward(GLOBAL_STREAM)).to eq([test_event])
    end

    specify 'delete_stream returns :ok when success' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect(client.delete_stream(stream)).to eq(:ok)
    end

    specify 'publish to default stream when not specified' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      test_event = TestEvent.new
      expect(client.publish_event(test_event)).to eq(:ok)
      expect(client.read_stream_events_forward(GLOBAL_STREAM)).to eq([test_event])
    end

    specify 'publish to multiple streams' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      test_event = TestEvent.new
      stream_names = [SecureRandom.uuid, SecureRandom.uuid]
      expect(client.publish_event(test_event, stream_name: stream_names)).to eq(:ok)
      stream_names.each do |stream_name|
        expect(client.read_stream_events_forward(stream_name)).to eq([test_event])
      end
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
      expect{ client.publish_event(third_event, stream_name: stream, expected_version: 0) }.to raise_error(WrongExpectedEventVersion)
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
      allow(Time).to receive(:now).and_return(now)
      allow_any_instance_of(Time).to receive(:utc).and_return(utc)
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      event = TestEvent.new
      client.publish_event(event)
      published = client.read_all_streams_forward
      expect(published.size).to eq(1)
      expect(published.first.metadata[:timestamp]).to eq(utc)
    end

    specify 'throws exception if subscriber is not defined' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.subscribe(nil, to: [])}.to raise_error(SubscriberNotExist)
      expect { client.subscribe_to_all_events(nil)}.to raise_error(SubscriberNotExist)
    end

    specify 'reading all existing stream names' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      client.publish_event(TestEvent.new, stream_name: 'test')

      expect(client.get_all_streams).to eq([Stream.new('all'), Stream.new('test')])
    end

    specify 'reading particular event' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      test_event = TestEvent.new
      client.publish_event(test_event, stream_name: 'test')

      expect(client.read_event(test_event.event_id)).to eq(test_event)
    end

    specify 'reading non-existent event' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect{client.read_event('72922e65-1b32-4e97-8023-03ae81dd3a27')}.to raise_error(EventNotFound)
    end

    specify 'link events' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event   = TestEvent.new
      second_event  = TestEvent.new
      client.subscribe_to_all_events(subscriber = Subscribers::ValidHandler.new)
      client.append_to_stream([first_event, second_event], stream_name: 'stream')
      client.link_to_stream(
        [first_event.event_id, second_event.event_id],
        stream_name: 'flow',
        expected_version: -1
      ).link_to_stream(
        [first_event.event_id],
        stream_name: 'cars',
      )
      expect(client.read_stream_events_forward('flow')).to eq([first_event, second_event])
      expect(client.read_stream_events_forward('cars')).to eq([first_event])
      expect(subscriber.handled_events).to be_empty
    end

  end
end
