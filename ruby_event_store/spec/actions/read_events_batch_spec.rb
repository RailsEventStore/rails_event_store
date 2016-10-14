require_relative '../spec_helper'

module RubyEventStore
  describe Client do
    let(:stream_name) { 'stream_name' }

    before do
      allow(Time).to receive(:now).and_return(Time.now)
    end

    specify 'raise exception if stream name is incorrect' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read_events_forward(nil, start: 1, count: 1) }.to raise_error(IncorrectStreamData)
      expect { client.read_events_forward('', start: 1, count: 1) }.to raise_error(IncorrectStreamData)
      expect { client.read_events_backward(nil, start: 1, count: 1) }.to raise_error(IncorrectStreamData)
      expect { client.read_events_backward('', start: 1, count: 1) }.to raise_error(IncorrectStreamData)
    end

    specify 'raise exception if event_id does not exist' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read_events_forward(stream_name, start: 0, count: 1) }.to raise_error(EventNotFound)
      expect { client.read_events_backward(stream_name, start: 0, count: 1) }.to raise_error(EventNotFound)
    end

    specify 'raise exception if event_id is not given or invalid' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read_events_forward(stream_name, start: nil, count: 1) }.to raise_error(InvalidPageStart)
      expect { client.read_events_backward(stream_name, start: :invalid, count: 1) }.to raise_error(InvalidPageStart)
    end

    specify 'fails when page size is invalid' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read_events_forward(stream_name, start: :head, count: 0) }.to raise_error(InvalidPageSize)
      expect { client.read_events_backward(stream_name, start: :head, count: 0) }.to raise_error(InvalidPageSize)
      expect { client.read_events_forward(stream_name, start: :head, count: -1) }.to raise_error(InvalidPageSize)
      expect { client.read_events_backward(stream_name, start: :head, count: -1) }.to raise_error(InvalidPageSize)
    end

    specify 'return all events ordered forward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      prepare_events_in_store(client)
      events = client.read_events_forward(stream_name, start: 1, count: 3)
      expect(events[0]).to eq(OrderCreated.new(event_id: '2'))
      expect(events[1]).to eq(OrderCreated.new(event_id: '3'))
    end

    specify 'return specified number of events ordered forward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      prepare_events_in_store(client)
      events = client.read_events_forward(stream_name, start: 1, count: 1)
      expect(events[0]).to eq(OrderCreated.new(event_id: '2'))
    end

    specify 'return all events ordered backward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      prepare_events_in_store(client)
      events = client.read_events_backward(stream_name, start: 2, count: 3)
      expect(events[0]).to eq(OrderCreated.new(event_id: '1'))
      expect(events[1]).to eq(OrderCreated.new(event_id: '0'))
    end

    specify 'return specified number of events ordered backward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      prepare_events_in_store(client)
      events = client.read_events_backward(stream_name, start: 3, count: 2)
      expect(events[0]).to eq(OrderCreated.new(event_id: '2'))
      expect(events[1]).to eq(OrderCreated.new(event_id: '1'))
    end

    specify 'fails when starting event not exists' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      prepare_events_in_store(client)
      expect{ client.read_events_forward(stream_name, start: SecureRandom.uuid, count: 1) }.to raise_error(EventNotFound)
      expect{ client.read_events_backward(stream_name, start: SecureRandom.uuid, count: 1) }.to raise_error(EventNotFound)
    end

    private

    def prepare_events_in_store(client)
      4.times do |index|
        event = OrderCreated.new(event_id: index)
        client.publish_event(event, stream_name: stream_name)
      end
    end
  end
end
