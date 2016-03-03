require_relative '../spec_helper'

module RubyEventStore
  describe Facade do
    let(:stream_name) { 'stream_name' }
    let(:page_size)   { 100 }

    specify 'raise exception if stream name is incorrect' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      expect { facade.delete_stream(nil) }.to raise_error(IncorrectStreamData)
      expect { facade.delete_stream('') }.to raise_error(IncorrectStreamData)
    end

    specify 'successfully delete streams of events' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      prepare_events_in_store(facade, 'test_1')
      prepare_events_in_store(facade, 'test_2')
      all_events = facade.read_all_streams_forward(:head, page_size)
      expect(all_events.length).to eq 8
      facade.delete_stream('test_2')
      all_events = facade.read_all_streams_forward(:head, page_size)
      expect(all_events.length).to eq 4
      expect(facade.read_stream_events_forward('test_2')).to eq []
    end

    private

    def prepare_events_in_store(facade, stream_name)
      4.times do |index|
        facade.publish_event(OrderCreated.new, stream_name)
      end
    end
  end
end
