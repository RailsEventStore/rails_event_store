require_relative '../spec_helper'

module RailsEventStore
  describe 'Read events in batch' do

    let(:repository)  { EventInMemoryRepository.new }
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
      response = client.read_events(stream_name, 1, 3)
      expect(response.length).to eq 3
      expect(response[0].event_id).to eq '1'
      expect(response[1].event_id).to eq '2'
      expect(response[2].event_id).to eq '3'
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
