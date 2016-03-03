require_relative '../spec_helper'

module RubyEventStore
  describe Facade do
    let(:stream_name) { 'stream_name' }

    specify 'raise exception if stream name is incorrect' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      expect { facade.read_events_forward(nil, 1, 1) }.to raise_error(IncorrectStreamData)
      expect { facade.read_events_forward('', 1, 1) }.to raise_error(IncorrectStreamData)
      expect { facade.read_events_backward(nil, 1, 1) }.to raise_error(IncorrectStreamData)
      expect { facade.read_events_backward('', 1, 1) }.to raise_error(IncorrectStreamData)
    end

    specify 'raise exception if event_id does not exist' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      expect { facade.read_events_forward(stream_name, 0, 1) }.to raise_error(EventNotFound)
      expect { facade.read_events_backward(stream_name, 0, 1) }.to raise_error(EventNotFound)
    end

    specify 'raise exception if event_id is not given or invalid' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      expect { facade.read_events_forward(stream_name, nil, 1) }.to raise_error(InvalidPageStart)
      expect { facade.read_events_backward(stream_name, :invalid, 1) }.to raise_error(InvalidPageStart)
    end

    specify 'fails when page size is invalid' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      expect { facade.read_events_forward(stream_name, :head, 0) }.to raise_error(InvalidPageSize)
      expect { facade.read_events_backward(stream_name, :head, 0) }.to raise_error(InvalidPageSize)
      expect { facade.read_events_forward(stream_name, :head, -1) }.to raise_error(InvalidPageSize)
      expect { facade.read_events_backward(stream_name, :head, -1) }.to raise_error(InvalidPageSize)
    end

    specify 'return all events ordered forward' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      prepare_events_in_store(facade)
      events = facade.read_events_forward(stream_name, 1, 3)
      expect(events[0]).to be_event({event_id: '2', event_type: 'OrderCreated', stream: stream_name, data: {}})
      expect(events[1]).to be_event({event_id: '3', event_type: 'OrderCreated', stream: stream_name, data: {}})
    end

    specify 'return specified number of events ordered forward' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      prepare_events_in_store(facade)
      events = facade.read_events_forward(stream_name, 1, 1)
      expect(events[0]).to be_event({event_id: '2', event_type: 'OrderCreated', stream: stream_name, data: {}})
    end

    specify 'return all events ordered backward' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      prepare_events_in_store(facade)
      events = facade.read_events_backward(stream_name, 2, 3)
      expect(events[0]).to be_event({event_id: '1', event_type: 'OrderCreated', stream: stream_name, data: {}})
      expect(events[1]).to be_event({event_id: '0', event_type: 'OrderCreated', stream: stream_name, data: {}})
    end

    specify 'return specified number of events ordered backward' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      prepare_events_in_store(facade)
      events = facade.read_events_backward(stream_name, 3, 2)
      expect(events[0]).to be_event({event_id: '2', event_type: 'OrderCreated', stream: stream_name, data: {}})
      expect(events[1]).to be_event({event_id: '1', event_type: 'OrderCreated', stream: stream_name, data: {}})
    end

    specify 'fails when starting event not exists' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      prepare_events_in_store(facade)
      expect{ facade.read_events_forward(stream_name, SecureRandom.uuid, 1) }.to raise_error(EventNotFound)
      expect{ facade.read_events_backward(stream_name, SecureRandom.uuid, 1) }.to raise_error(EventNotFound)
    end

    private

    def prepare_events_in_store(facade)
      4.times do |index|
        event = OrderCreated.new(event_id: index)
        facade.publish_event(event, stream_name)
      end
    end
  end
end
