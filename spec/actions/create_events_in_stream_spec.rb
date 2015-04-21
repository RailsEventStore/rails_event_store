require_relative '../spec_helper'
require 'ostruct'

module RailsEventStore
  describe 'Appending events to stream' do

    let(:repository)  { EventInMemoryRepository.new }
    let(:client)      { RailsEventStore::Client.new(repository) }
    let(:stream_name) { 'stream_name' }

    before(:each) do
      repository.reset!
    end

    specify 'create successfully event' do
      event = OrderCreated.new({data: 'sample', event_id: 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd'})
      client.publish_event(event, stream_name)
      expect(repository.db.length).to eq 1
      expect(repository.db[0].stream).to eq stream_name
      expect(repository.db[0].event_type).to eq 'OrderCreated'
      expect(repository.db[0].event_id).to eq 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd'
      expect(repository.db[0].data).to eq('sample')
    end

    specify 'generate guid and create successfully event' do
      event = OrderCreated.new({data: 'sample'})
      client.publish_event(event, stream_name)
      expect(repository.db.length).to eq 1
      expect(repository.db[0].event_id).to_not be_nil
    end

    specify 'raise exception if event version incorrect' do
      event = OrderCreated.new({data: 'sample'})
      client.publish_event(event, stream_name)
      expect{client.publish_event(event, stream_name, 'wrong_id')}.to raise_error(WrongExpectedEventVersion)
    end

    specify 'raise exception if event data incorrect' do
      incorrect_event = OrderCreated.new({data: nil})
      expect{client.publish_event(incorrect_event, stream_name)}.to raise_error(IncorrectStreamData)
    end

    specify 'create global event without stream name' do
      event = OrderCreated.new({data: 'sample'})
      client.publish_event(event)
      expect(repository.db.length).to eq 1
      expect(repository.db[0].event_type).to eq 'OrderCreated'
      expect(repository.db[0].data).to eq('sample')
      expect(repository.db[0].stream).to eq 'all'
    end
  end
end