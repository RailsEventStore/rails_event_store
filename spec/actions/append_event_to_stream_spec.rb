require 'spec_helper'
require 'ostruct'
require_relative '../example_invoicing_app'

module RailsEventStore
  describe Actions::AppendEventToStream do

    let(:repository)  { EventInMemoryRepository.new }
    let(:service)     { Actions::AppendEventToStream.new(repository) }
    let(:stream_name) { 'stream_name' }

    before(:each) do
      repository.reset!
    end

    specify 'create successfully event' do
      event = OrderCreated.new({data: 'sample', event_id: 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd'})
      service.call(stream_name, event, nil)
      expect(repository.db.length).to eq 1
      expect(repository.db[0].stream).to eq stream_name
      expect(repository.db[0].event_type).to eq 'OrderCreated'
      expect(repository.db[0].event_id).to eq 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd'
      expect(repository.db[0].data).to eq('sample')
    end

    specify 'generate guid and create successfully event' do
      event = OrderCreated.new({data: 'sample'})
      service.call(stream_name, event, nil)
      expect(repository.db.length).to eq 1
      expect(repository.db[0].event_id).to_not be_nil
    end

    specify 'raise exception if event version incorrect' do
      event = OrderCreated.new({data: 'sample'})
      service.call(stream_name, event, nil)
      expect{service.call(stream_name, event, 'wrong_id')}.to raise_error(WrongExpectedEventVersion)
    end

    specify 'raise exception if event data incorrect' do
      incorrect_event = OrderCreated.new({data: nil})
      expect{service.call(stream_name, incorrect_event, nil)}.to raise_error(IncorrectStreamData)
    end

    specify 'create global event without stream name' do
      event = OrderCreated.new({data: 'sample'})
      service.call('all', event, nil)
      expect(repository.db.length).to eq 1
      expect(repository.db[0].event_type).to eq 'OrderCreated'
      expect(repository.db[0].data).to eq('sample')
      expect(repository.db[0].stream).to eq 'all'
    end
  end
end