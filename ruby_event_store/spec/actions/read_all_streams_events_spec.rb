require_relative '../spec_helper'

module RubyEventStore
  describe Facade do

    let(:repository)  { InMemoryRepository.new }
    let(:facade)      { RubyEventStore::Facade.new(repository) }
    let(:stream_name) { 'stream_name' }

    before(:each) do
      repository.reset!
    end

    specify 'return all events ordered forward' do
      prepare_events_in_store('order_1')
      prepare_events_in_store('order_2')
      response = facade.read_all_streams
      expect(response.length).to be 2
      expect(response[0].event_id).to eq '0'
      expect(response[1].event_id).to eq '0'
    end

    private

    def prepare_events_in_store(stream_name)
      1.times do |index|
        event = OrderCreated.new(event_id: index)
        create_event(event, stream_name)
      end
    end

    def create_event(event, stream_name)
      facade.publish_event(event, stream_name)
    end
  end
end
