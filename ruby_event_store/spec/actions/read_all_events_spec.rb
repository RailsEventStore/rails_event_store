require_relative '../spec_helper'

module RubyEventStore
  RSpec.describe Client do
    let(:stream_name) { 'stream_name' }

    before do
      allow(Time).to receive(:now).and_return(Time.now)
    end

    specify 'raise exception if stream name is incorrect' do
      client = RubyEventStore::Client.new(repository: Repositories::InMemory.new)
      expect { client.read_stream_events_forward(nil) }.to raise_error(IncorrectStreamData)
      expect { client.read_stream_events_forward('') }.to raise_error(IncorrectStreamData)
      expect { client.read_stream_events_backward(nil) }.to raise_error(IncorrectStreamData)
      expect { client.read_stream_events_backward('') }.to raise_error(IncorrectStreamData)
    end

    specify 'return all events ordered forward' do
      client = RubyEventStore::Client.new(repository: Repositories::InMemory.new)
      prepare_events_in_store(client)
      events = client.read_stream_events_forward(stream_name)
      expect(events[0]).to eq(OrderCreated.new(event_id: '0'))
      expect(events[1]).to eq(OrderCreated.new(event_id: '1'))
      expect(events[2]).to eq(OrderCreated.new(event_id: '2'))
      expect(events[3]).to eq(OrderCreated.new(event_id: '3'))
    end

    specify 'return all events ordered backward' do
      client = RubyEventStore::Client.new(repository: Repositories::InMemory.new)
      prepare_events_in_store(client)
      events = client.read_stream_events_backward(stream_name)
      expect(events[0]).to eq(OrderCreated.new(event_id: '3'))
      expect(events[1]).to eq(OrderCreated.new(event_id: '2'))
      expect(events[2]).to eq(OrderCreated.new(event_id: '1'))
      expect(events[3]).to eq(OrderCreated.new(event_id: '0'))
    end

    private

    def prepare_events_in_store(client)
      4.times do |index|
        event = OrderCreated.new(event_id: index)
        client.publish_event(event, stream_name: stream_name)
      end
    end
  end
end
