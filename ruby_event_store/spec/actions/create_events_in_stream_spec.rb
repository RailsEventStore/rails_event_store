require_relative '../spec_helper'
require 'ostruct'

module RubyEventStore
  describe Client do
    let(:stream_name) { 'stream_name' }

    specify 'create successfully event' do
      client = RubyEventStore::Client.new(InMemoryRepository.new)
      event = OrderCreated.new(event_id: 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd')
      client.append_to_stream(stream_name, event)
      saved_events = client.read_stream_events_forward(stream_name)
      expect(saved_events[0]).to eq(event)
    end

    specify 'generate guid and create successfully event' do
      client = RubyEventStore::Client.new(InMemoryRepository.new)
      event = OrderCreated.new
      client.append_to_stream(stream_name, event)
      saved_events = client.read_stream_events_forward(stream_name)
      expect(saved_events[0]).to eq(event)
    end

    specify 'raise exception if event version incorrect' do
      client = RubyEventStore::Client.new(InMemoryRepository.new)
      event = OrderCreated.new
      client.append_to_stream(stream_name, event)
      expect { client.publish_event(event, stream_name: stream_name, expected_version: 'wrong_id') }.to raise_error(WrongExpectedEventVersion)
    end

    specify 'create event with optimistic locking' do
      client = RubyEventStore::Client.new(InMemoryRepository.new)
      event_id_0 = 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd'
      event = OrderCreated.new(event_id: event_id_0)
      client.append_to_stream(stream_name, event)

      event_id_1 = '724dd49d-6e20-40e6-bc32-ed75258f886b'
      event = OrderCreated.new(event_id: event_id_1)
      client.append_to_stream(stream_name, event, expected_version: 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd')
    end

    specify 'expect no event handler is called' do
      client = RubyEventStore::Client.new(InMemoryRepository.new)
      handler = double(:event_handler)
      expect(handler).not_to receive(:call)
      event = OrderCreated.new
      client.subscribe_to_all_events(handler)
      client.append_to_stream(stream_name, event)
      saved_events = client.read_stream_events_forward(stream_name)
      expect(saved_events[0]).to eq(event)
    end

    specify 'expect publish to call event handlers' do
      client = RubyEventStore::Client.new(InMemoryRepository.new)
      handler = double(:event_handler)
      expect(handler).to receive(:call)
      event = OrderCreated.new
      client.subscribe_to_all_events(handler)
      client.publish_event(event, stream_name: stream_name)
      saved_events = client.read_stream_events_forward(stream_name)
      expect(saved_events[0]).to eq(event)
    end

    specify 'create global event without stream name' do
      client = RubyEventStore::Client.new(InMemoryRepository.new)
      event = OrderCreated.new
      client.publish_event(event)
      saved_events = client.read_stream_events_forward('all')
      expect(saved_events[0]).to eq(event)
    end
  end
end
