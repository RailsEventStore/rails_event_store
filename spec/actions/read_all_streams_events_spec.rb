require_relative '../spec_helper'

module RailsEventStore
  describe Client do

    let(:repository)  { EventInMemoryRepository.new }
    let(:client)      { RailsEventStore::Client.new(repository) }
    let(:stream_name) { 'stream_name' }

    before(:each) do
      repository.reset!
    end

    specify 'return all events ordered forward' do
      prepare_events_in_store('order_1')
      prepare_events_in_store('order_2')
      response = client.read_all_streams
      expect(response['order_1'].length).to be 1
      expect(response['order_1'][0].event_id).to eq '0'
      expect(response['order_2'].length).to be 1
      expect(response['order_1'][0].event_id).to eq '0'
    end

    private

    def prepare_events_in_store(stream_name)
      1.times do |index|
        event = OrderCreated.new({data: {data: 'sample'}, event_id: index})
        create_event(event, stream_name)
      end
    end

    def create_event(event, stream_name)
      client.publish_event(event, stream_name)
    end
  end
end
