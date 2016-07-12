require_relative '../spec_helper'

module RubyEventStore
  describe Facade do
    let(:page_size)   { 100 }

    specify 'return all events ordered forward' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      facade.publish_event(OrderCreated.new(data: { order_id: 123 }), 'order_1')
      facade.publish_event(OrderCreated.new(data: { order_id: 234 }), 'order_2')
      response = facade.read_all_streams_forward(:head, page_size)
      expect(response.length).to be 2
      expect(response[0].data.order_id).to eq 123
      expect(response[1].data.order_id).to eq 234
    end

    specify 'return batch of events from the beginging ordered forward' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      facade.publish_event(OrderCreated.new(data: { order_id: 123 }), 'order_1')
      facade.publish_event(OrderCreated.new(data: { order_id: 234 }), 'order_2')
      facade.publish_event(OrderCreated.new(data: { order_id: 345 }), 'order_3')
      response = facade.read_all_streams_forward(:head, 2)
      expect(response.length).to be 2
      expect(response[0].data.order_id).to eq 123
      expect(response[1].data.order_id).to eq 234
    end

    specify 'return batch of events from given event ordered forward' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      uid = SecureRandom.uuid
      facade.publish_event(OrderCreated.new(event_id: uid, data: { order_id: 123 }), 'order_1')
      facade.publish_event(OrderCreated.new(data: { order_id: 234 }), 'order_2')
      facade.publish_event(OrderCreated.new(data: { order_id: 345 }), 'order_3')
      response = facade.read_all_streams_forward(uid, 1)
      expect(response.length).to be 1
      expect(response[0].data.order_id).to eq 234
    end

    specify 'return all events ordered backward' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      facade.publish_event(OrderCreated.new(data: { order_id: 123 }), 'order_1')
      facade.publish_event(OrderCreated.new(data: { order_id: 234 }), 'order_1')
      response = facade.read_all_streams_backward(:head, page_size)
      expect(response.length).to be 2
      expect(response[0].data.order_id).to eq 234
      expect(response[1].data.order_id).to eq 123
    end

    specify 'return batch of events from the end ordered backward' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      facade.publish_event(OrderCreated.new(data: { order_id: 123 }), 'order_1')
      facade.publish_event(OrderCreated.new(data: { order_id: 234 }), 'order_2')
      facade.publish_event(OrderCreated.new(data: { order_id: 345 }), 'order_3')
      response = facade.read_all_streams_backward(:head, 2)
      expect(response.length).to be 2
      expect(response[0].data.order_id).to eq 345
      expect(response[1].data.order_id).to eq 234
    end

    specify 'return batch of events from given event ordered backward' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      uid = SecureRandom.uuid
      facade.publish_event(OrderCreated.new(data: { order_id: 123 }), 'order_1')
      facade.publish_event(OrderCreated.new(event_id: uid, data: { order_id: 234 }), 'order_2')
      facade.publish_event(OrderCreated.new(data: { order_id: 345 }), 'order_3')
      response = facade.read_all_streams_backward(uid, 1)
      expect(response.length).to be 1
      expect(response[0].data.order_id).to eq 123
    end

    specify 'fails when starting event not exists' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      facade.publish_event(OrderCreated.new(data: { order_id: 123 }), 'order_1')
      expect{ facade.read_all_streams_forward(SecureRandom.uuid, 1) }.to raise_error(EventNotFound)
      expect{ facade.read_all_streams_backward(SecureRandom.uuid, 1) }.to raise_error(EventNotFound)
    end

    specify 'fails when page size is invalid' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      facade.publish_event(OrderCreated.new(data: { order_id: 123 }), 'order_1')
      expect{ facade.read_all_streams_forward(:head, 0) }.to raise_error(InvalidPageSize)
      expect{ facade.read_all_streams_backward(:head, 0) }.to raise_error(InvalidPageSize)
      expect{ facade.read_all_streams_forward(:head, -1) }.to raise_error(InvalidPageSize)
      expect{ facade.read_all_streams_backward(:head, -1) }.to raise_error(InvalidPageSize)
    end
  end
end
