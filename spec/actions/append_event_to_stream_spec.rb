require 'spec_helper'
require 'ostruct'

module RailsEventStore
  describe Actions::AppendEventToStream do

    let(:repository)  { EventInMemoryRepository.new }
    let(:service)     { Actions::AppendEventToStream.new(repository) }
    let(:stream_name) { 'stream_name' }

    before(:each) do
      repository.reset!
    end

    specify 'create successfully event from hash in stream' do
      event_data = hash_event_data('OrderCreated', {data: 'sample'}, 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd')
      service.call(stream_name, event_data, nil)
      expect(repository.db.length).to eq 1
      expect(repository.db[0].stream).to eq stream_name
      expect(repository.db[0].event_type).to eq 'OrderCreated'
      expect(repository.db[0].event_id).to eq 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd'
      expect(repository.db[0].data).to eq({data: 'sample'})
    end

    specify 'create successfully event from struct in stream' do
      event_data = struct_event_data('OrderCreated', {data: 'sample'}, 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd')
      service.call(stream_name, event_data, nil)
      expect(repository.db.length).to eq 1
      expect(repository.db[0].stream).to eq stream_name
      expect(repository.db[0].event_type).to eq 'OrderCreated'
      expect(repository.db[0].event_id).to eq 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd'
      expect(repository.db[0].data).to eq({data: 'sample'})
    end

    specify 'generate guid and create successfully event from hash in stream' do
      event_data = hash_event_data('OrderCreated', {data: 'sample'})
      service.call(stream_name, event_data, nil)
      expect(repository.db.length).to eq 1
      expect(repository.db[0].event_id).to_not be_nil
    end

    specify 'generate guid and create successfully event from struct in stream' do
      event_data = struct_event_data('OrderCreated', {data: 'sample'})
      service.call(stream_name, event_data, nil)
      expect(repository.db.length).to eq 1
      expect(repository.db[0].event_id).to_not be_nil
    end

    specify 'raise exception if event version incorrect' do
      event_data = hash_event_data('OrderCreated', {data: 'sample'})
      service.call(stream_name, event_data, nil)
      expect{service.call(stream_name, event_data, 'wrong_id')}.to raise_error(WrongExpectedEventVersion)
    end

    specify 'raise exception if event data incorrect' do
      event_data_1 = hash_event_data(nil, {data: 'sample'})
      event_data_2 = hash_event_data('OrderCreated', nil)
      expect{service.call(stream_name, event_data_1, nil)}.to raise_error(IncorrectStreamData)
      expect{service.call(stream_name, event_data_2, nil)}.to raise_error(IncorrectStreamData)
    end


    private

    def hash_event_data(type, data, guid = nil)
      event_data ={
          event_type: type,
          data: data
      }
      event_data.merge!({event_id: guid}) if guid
      event_data
    end

    def struct_event_data(type, data, guid = nil)
      if guid
        OpenStruct.new(data: data, event_type: type, event_id: guid)
      else
        OpenStruct.new(data: data, event_type: type)
      end
    end
  end
end