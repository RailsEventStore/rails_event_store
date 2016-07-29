require_relative '../spec_helper'

module RubyEventStore
  describe Client do
    let(:stream_name) { 'stream_name' }
    let(:page_size)   { 100 }

    specify 'raise exception if stream name is incorrect' do
      client = RubyEventStore::Client.new(InMemoryRepository.new)
      expect { client.delete_stream(nil) }.to raise_error(IncorrectStreamData)
      expect { client.delete_stream('') }.to raise_error(IncorrectStreamData)
    end

    specify 'successfully delete streams of events' do
      client = RubyEventStore::Client.new(InMemoryRepository.new)
      prepare_events_in_store(client, 'test_1')
      prepare_events_in_store(client, 'test_2')
      all_events = client.read_all_streams_forward(:head, page_size)
      expect(all_events.length).to eq 8
      client.delete_stream('test_2')
      all_events = client.read_all_streams_forward(:head, page_size)
      expect(all_events.length).to eq 4
      expect(client.read_stream_events_forward('test_2')).to eq []
    end

    private

    def prepare_events_in_store(client, stream_name)
      4.times do |index|
        client.publish_event(OrderCreated.new, stream_name: stream_name)
      end
    end
  end
end
