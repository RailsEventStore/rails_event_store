require_relative '../spec_helper'
require 'ostruct'

module RailsEventStore
  describe Client do

    let(:repository) { EventInMemoryRepository.new }
    let(:client) { RailsEventStore::Client.new(repository) }
    let(:stream_name) { 'stream_name' }

    before(:each) do
      repository.reset!
    end

    specify 'create successfully event' do
      event = OrderCreated.new({event_id: 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd'})
      client.publish_event(event, stream_name)
      saved_events = client.read_all_events(stream_name)
      expected = {event_id: 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd', event_type: 'OrderCreated', stream: stream_name}
      expect(saved_events[0]).to be_event(expected)
    end

    specify 'generate guid and create successfully event' do
      event = OrderCreated.new
      client.publish_event(event, stream_name)
      saved_events = client.read_all_events(stream_name)
      expected = {event_type: 'OrderCreated', stream: stream_name}
      expect(saved_events[0]).to be_event(expected)
    end

    specify 'raise exception if event version incorrect' do
      event = OrderCreated.new
      client.publish_event(event, stream_name)
      expect { client.publish_event(event, stream_name, 'wrong_id') }.to raise_error(WrongExpectedEventVersion)
    end

    specify 'create global event without stream name' do
      event = OrderCreated.new
      client.publish_event(event)
      saved_events = client.read_all_events('all')
      expected = {event_type: 'OrderCreated', stream: 'all'}
      expect(saved_events[0]).to be_event(expected)
    end

    specify 'create event with optimistic locking' do
      event_id_0 = "b2d506fd-409d-4ec7-b02f-c6d2295c7edd"
      event = OrderCreated.new({event_id: event_id_0})
      client.publish_event(event, stream_name)

      event_id_1 = "724dd49d-6e20-40e6-bc32-ed75258f886b"
      event = OrderCreated.new({event_id: event_id_1})
      client.publish_event(event, stream_name, event_id_0)
    end
  end
end
