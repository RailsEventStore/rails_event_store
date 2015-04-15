require 'spec_helper'

module RailsEventStore
  describe Actions::ReadAllStreams do

    let(:repository)  { EventInMemoryRepository.new }
    let(:service)     { Actions::ReadAllStreams.new(repository) }
    let(:stream_name) { 'stream_name' }

    before(:each) do
      repository.reset!
    end

    specify 'return all events ordered forward' do
      prepare_events_in_store('order_1')
      prepare_events_in_store('order_2')
      response = service.call
      expect(response['order_1'].length).to be 1
      expect(response['order_1'][0].event_id).to eq '0'
      expect(response['order_2'].length).to be 1
      expect(response['order_1'][0].event_id).to eq '0'
    end

    private

    def prepare_events_in_store(stream_name)
      1.times do |index|
        event_data = {event_type: 'OrderCreated',
                      data: {data: 'sample'},
                      event_id: index}
        create_event(event_data, stream_name)
      end
    end

    def create_event(event_data, stream_name)
      Actions::AppendEventToStream.new(repository).call(stream_name, event_data, nil)
    end
  end
end
