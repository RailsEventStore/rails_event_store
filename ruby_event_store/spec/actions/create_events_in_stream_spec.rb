require_relative '../spec_helper'
require 'ostruct'

module RubyEventStore
  describe Facade do

    let(:repository)  { InMemoryRepository.new }
    let(:facade)      { RubyEventStore::Facade.new(repository) }
    let(:stream_name) { 'stream_name' }

    before(:each) do
      repository.reset!
    end

    specify 'create successfully event' do
      event = OrderCreated.new(event_id: 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd')
      facade.append_to_stream(stream_name, event)
      saved_events = facade.read_stream_events_forward(stream_name)
      expected = {event_id: 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd', event_type: 'OrderCreated', data: {}}
      expect(saved_events[0]).to be_event(expected)
    end

    specify 'generate guid and create successfully event' do
      event = OrderCreated.new
      facade.append_to_stream(stream_name, event)
      saved_events = facade.read_stream_events_forward(stream_name)
      expected = {event_type: 'OrderCreated', data: {}}
      expect(saved_events[0]).to be_event(expected)
    end

    specify 'raise exception if event version incorrect' do
      event = OrderCreated.new
      facade.append_to_stream(stream_name, event)
      expect { facade.publish_event(event, stream_name, 'wrong_id') }.to raise_error(WrongExpectedEventVersion)
    end

    specify 'create event with optimistic locking' do
      event_id_0 = 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd'
      event = OrderCreated.new(event_id: event_id_0)
      facade.append_to_stream(stream_name, event)

      event_id_1 = '724dd49d-6e20-40e6-bc32-ed75258f886b'
      event = OrderCreated.new(event_id: event_id_1)
      facade.append_to_stream(stream_name, event, event_id_0)
    end

    specify 'expect no event handler is called' do
      handler = double(:event_handler)
      expect(handler).not_to receive(:handle_event)
      event = OrderCreated.new
      facade.subscribe_to_all_events(handler)
      facade.append_to_stream(stream_name, event)
      saved_events = facade.read_stream_events_forward(stream_name)
      expected = {event_type: 'OrderCreated', data: {}}
      expect(saved_events[0]).to be_event(expected)
    end

    specify 'expect publish to call event handlers' do
      handler = double(:event_handler)
      expect(handler).to receive(:handle_event)
      event = OrderCreated.new
      facade.subscribe_to_all_events(handler)
      facade.publish_event(event, stream_name)
      saved_events = facade.read_stream_events_forward(stream_name)
      expected = {event_type: 'OrderCreated', data: {}}
      expect(saved_events[0]).to be_event(expected)
    end

    specify 'create global event without stream name' do
      event = OrderCreated.new
      facade.publish_event(event)
      saved_events = facade.read_stream_events_forward('all')
      expected = {event_type: 'OrderCreated', stream: 'all', data: {}}
      expect(saved_events[0]).to be_event(expected)
    end
  end
end
