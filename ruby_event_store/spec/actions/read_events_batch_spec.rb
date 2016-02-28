require_relative '../spec_helper'

module RubyEventStore
  describe Facade do

    let(:repository)  { InMemoryRepository.new }
    let(:facade)      { RubyEventStore::Facade.new(repository) }
    let(:stream_name) { 'stream_name' }

    before(:each) do
      repository.reset!
    end

    specify 'raise exception if stream name is incorrect' do
      expect { facade.read_events(nil, 1, 1) }.to raise_error(IncorrectStreamData)
      expect { facade.read_events('', 1, 1) }.to raise_error(IncorrectStreamData)
    end

    specify 'raise exception if event_id doesnt exist' do
      expect { facade.read_events(stream_name, 0, 1) }.to raise_error(EventNotFound)
    end

    specify 'return all events ordered forward' do
      prepare_events_in_store
      events = facade.read_events(stream_name, 1, 3)
      expect(events[0]).to be_event({event_id: '1', event_type: 'OrderCreated', stream: stream_name, data: {}})
      expect(events[1]).to be_event({event_id: '2', event_type: 'OrderCreated', stream: stream_name, data: {}})
      expect(events[2]).to be_event({event_id: '3', event_type: 'OrderCreated', stream: stream_name, data: {}})
    end

    private

    def prepare_events_in_store
      4.times do |index|
        event = OrderCreated.new(event_id: index)
        create_event(event, stream_name)
      end
    end

    def create_event(event, stream_name)
      facade.publish_event(event, stream_name)
    end
  end
end
