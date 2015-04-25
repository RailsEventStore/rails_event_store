require_relative '../spec_helper'

module RailsEventStore
  describe 'Deleting events' do

    let(:repository)  { Repositories::EventInMemoryRepository.new }
    let(:client)      { RailsEventStore::Client.new(repository) }
    let(:stream_name) { 'stream_name' }

    before(:each) do
      repository.reset!
    end

    specify 'raise exception if stream name is incorrect' do
      expect { client.delete_stream(nil) }.to raise_error(IncorrectStreamData)
      expect { client.delete_stream('') }.to raise_error(IncorrectStreamData)
    end

    specify 'create successfully delete streams events' do
      prepare_events_in_store('test_1')
      prepare_events_in_store('test_2')
      all_events = client.read_all_streams
      expect(all_events['test_1'].length).to eq 4
      expect(all_events['test_2'].length).to eq 4
      client.delete_stream('test_2')
      all_events = client.read_all_streams
      expect(all_events['test_1'].length).to eq 4
      expect(all_events['test_2']).to eq nil
    end

    private

    def prepare_events_in_store(stream_name)
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
