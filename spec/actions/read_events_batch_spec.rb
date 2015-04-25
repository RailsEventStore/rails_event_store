require_relative '../spec_helper'

module RailsEventStore
  describe 'Read events in batch' do

    let(:repository)  { Repositories::EventInMemoryRepository.new }
    let(:client)      { RailsEventStore::Client.new(repository) }
    let(:stream_name) { 'stream_name' }

    before(:each) do
      repository.reset!
    end

    specify 'raise exception if stream name is incorrect' do
      expect { client.read_events(nil, 1, 1) }.to raise_error(IncorrectStreamData)
      expect { client.read_events('', 1, 1) }.to raise_error(IncorrectStreamData)
    end

    specify 'return all events ordered forward' do
      prepare_events_in_store
      events = client.read_events(stream_name, 1, 3)
      expect(events[0]).to be_event({data: {data: 'sample'}, event_id: '1', event_type: 'OrderCreated', stream: stream_name})
      expect(events[1]).to be_event({data: {data: 'sample'}, event_id: '2', event_type: 'OrderCreated', stream: stream_name})
      expect(events[2]).to be_event({data: {data: 'sample'}, event_id: '3', event_type: 'OrderCreated', stream: stream_name})
    end

    private

    def prepare_events_in_store
      4.times do |index|
        event = OrderCreated.new({data: {data: 'sample'}, event_id: index})
        create_event(event, stream_name)
      end
    end

    def create_event(event, stream_name)
      client.publish_event(event, stream_name)
    end
  end
end
