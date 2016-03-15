require_relative '../spec_helper'
require 'ostruct'

module RubyEventStore
  describe Facade do
    let(:stream_name) { 'stream_name' }

    specify 'create successfully event' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      event = OrderCreated.new(event_id: 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd')
      facade.append_to_stream(stream_name, event)
      saved_events = facade.read_stream_events_forward(stream_name)
      expect(saved_events[0]).to eq(event)
    end

    specify 'generate guid and create successfully event' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      event = OrderCreated.new
      facade.append_to_stream(stream_name, event)
      saved_events = facade.read_stream_events_forward(stream_name)
      expect(saved_events[0]).to eq(event)
    end

    specify 'raise exception if event version incorrect' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      event = OrderCreated.new
      facade.append_to_stream(stream_name, event)
      expect { facade.publish_event(event, stream_name, 'wrong_id') }.to raise_error(WrongExpectedEventVersion)
    end

    specify 'create event with optimistic locking' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      event_id_0 = 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd'
      event = OrderCreated.new(event_id: event_id_0)
      facade.append_to_stream(stream_name, event)

      event_id_1 = '724dd49d-6e20-40e6-bc32-ed75258f886b'
      event = OrderCreated.new(event_id: event_id_1)
      facade.append_to_stream(stream_name, event, event_id_0)
    end

    specify 'expect no event handler is called' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      handler = double(:event_handler)
      expect(handler).not_to receive(:handle_event)
      event = OrderCreated.new
      facade.subscribe_to_all_events(handler)
      facade.append_to_stream(stream_name, event)
      saved_events = facade.read_stream_events_forward(stream_name)
      expect(saved_events[0]).to eq(event)
    end

    specify 'expect publish to call event handlers' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      handler = double(:event_handler)
      expect(handler).to receive(:handle_event)
      event = OrderCreated.new
      facade.subscribe_to_all_events(handler)
      facade.publish_event(event, stream_name)
      saved_events = facade.read_stream_events_forward(stream_name)
      expect(saved_events[0]).to eq(event)
    end

    specify 'create global event without stream name' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      event = OrderCreated.new
      facade.publish_event(event)
      saved_events = facade.read_stream_events_forward('all')
      expect(saved_events[0]).to eq(event)
    end
  end
end
