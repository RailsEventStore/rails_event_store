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
      expect { facade.delete_stream(nil) }.to raise_error(IncorrectStreamData)
      expect { facade.delete_stream('') }.to raise_error(IncorrectStreamData)
    end

    specify 'create successfully delete streams events' do
      prepare_events_in_store('test_1')
      prepare_events_in_store('test_2')
      all_events = facade.read_all_streams_forward
      expect(all_events.length).to eq 8
      facade.delete_stream('test_2')
      all_events = facade.read_all_streams_forward
      expect(all_events.length).to eq 4
      expect(facade.read_stream_events_forward('test_2')).to eq []
    end

    private

    def prepare_events_in_store(stream_name)
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
