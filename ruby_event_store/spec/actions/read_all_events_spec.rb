require_relative '../spec_helper'

module RubyEventStore
  describe Facade do
    let(:stream_name) { 'stream_name' }

    specify 'raise exception if stream name is incorrect' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      expect { facade.read_stream_events_forward(nil) }.to raise_error(IncorrectStreamData)
      expect { facade.read_stream_events_forward('') }.to raise_error(IncorrectStreamData)
      expect { facade.read_stream_events_backward(nil) }.to raise_error(IncorrectStreamData)
      expect { facade.read_stream_events_backward('') }.to raise_error(IncorrectStreamData)
    end

    specify 'return all events ordered forward' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      prepare_events_in_store(facade)
      events = facade.read_stream_events_forward(stream_name)
      expect(events[0]).to be_event({event_id: '0', event_type: 'OrderCreated', data: {}})
      expect(events[1]).to be_event({event_id: '1', event_type: 'OrderCreated', data: {}})
      expect(events[2]).to be_event({event_id: '2', event_type: 'OrderCreated', data: {}})
      expect(events[3]).to be_event({event_id: '3', event_type: 'OrderCreated', data: {}})
    end

    specify 'return all events ordered backward' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      prepare_events_in_store(facade)
      events = facade.read_stream_events_backward(stream_name)
      expect(events[0]).to be_event({event_id: '3', event_type: 'OrderCreated', data: {}})
      expect(events[1]).to be_event({event_id: '2', event_type: 'OrderCreated', data: {}})
      expect(events[2]).to be_event({event_id: '1', event_type: 'OrderCreated', data: {}})
      expect(events[3]).to be_event({event_id: '0', event_type: 'OrderCreated', data: {}})
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
