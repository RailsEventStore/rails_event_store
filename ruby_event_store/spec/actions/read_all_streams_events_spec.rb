require_relative '../spec_helper'

module RubyEventStore
  describe Facade do

    let(:repository)  { InMemoryRepository.new }
    let(:facade)      { RubyEventStore::Facade.new(repository) }

    before(:each) do
      repository.reset!
    end

    specify 'return all events ordered forward' do
      facade.publish_event(OrderCreated.new(order_id: 123), 'order_1')
      facade.publish_event(OrderCreated.new(order_id: 234), 'order_2')
      response = facade.read_all_streams_forward
      expect(response.length).to be 2
      expect(response[0].order_id).to eq 123
      expect(response[1].order_id).to eq 234
    end

    specify 'return batch of events from the beginging ordered forward' do
      facade.publish_event(OrderCreated.new(order_id: 123), 'order_1')
      facade.publish_event(OrderCreated.new(order_id: 234), 'order_2')
      facade.publish_event(OrderCreated.new(order_id: 345), 'order_3')
      response = facade.read_all_streams_forward(nil, 2)
      expect(response.length).to be 2
      expect(response[0].order_id).to eq 123
      expect(response[1].order_id).to eq 234
    end

    specify 'return batch of events from given event ordered forward' do
      uid = SecureRandom.uuid
      facade.publish_event(OrderCreated.new(event_id: uid, order_id: 123), 'order_1')
      facade.publish_event(OrderCreated.new(order_id: 234), 'order_2')
      facade.publish_event(OrderCreated.new(order_id: 345), 'order_3')
      response = facade.read_all_streams_forward(uid, 1)
      expect(response.length).to be 1
      expect(response[0].order_id).to eq 234
    end

    specify 'return all events ordered backward' do
      facade.publish_event(OrderCreated.new(order_id: 123), 'order_1')
      facade.publish_event(OrderCreated.new(order_id: 234), 'order_1')
      response = facade.read_all_streams_backward
      expect(response.length).to be 2
      expect(response[0].order_id).to eq 234
      expect(response[1].order_id).to eq 123
    end

    specify 'return batch of events from the end ordered backward' do
      facade.publish_event(OrderCreated.new(order_id: 123), 'order_1')
      facade.publish_event(OrderCreated.new(order_id: 234), 'order_2')
      facade.publish_event(OrderCreated.new(order_id: 345), 'order_3')
      response = facade.read_all_streams_backward(nil, 2)
      expect(response.length).to be 2
      expect(response[0].order_id).to eq 345
      expect(response[1].order_id).to eq 234
    end

    specify 'return batch of events from given event ordered backward' do
      uid = SecureRandom.uuid
      facade.publish_event(OrderCreated.new(order_id: 123), 'order_1')
      facade.publish_event(OrderCreated.new(event_id: uid, order_id: 234), 'order_2')
      facade.publish_event(OrderCreated.new(order_id: 345), 'order_3')
      response = facade.read_all_streams_backward(uid, 1)
      expect(response.length).to be 1
      expect(response[0].order_id).to eq 123
    end

    specify 'fails when starting event not exists' do
      facade.publish_event(OrderCreated.new(order_id: 123), 'order_1')
      expect{ facade.read_all_streams_forward(SecureRandom.uuid, 1) }.to raise_error(EventNotFound)
      expect{ facade.read_all_streams_backward(SecureRandom.uuid, 1) }.to raise_error(EventNotFound)
    end

    specify 'fails when page size is invalid' do
      facade.publish_event(OrderCreated.new(order_id: 123), 'order_1')
      expect{ facade.read_all_streams_forward(SecureRandom.uuid, 0) }.to raise_error(ArgumentError)
      expect{ facade.read_all_streams_backward(SecureRandom.uuid, 0) }.to raise_error(ArgumentError)
      expect{ facade.read_all_streams_forward(SecureRandom.uuid, -1) }.to raise_error(ArgumentError)
      expect{ facade.read_all_streams_backward(SecureRandom.uuid, -1) }.to raise_error(ArgumentError)
    end

    specify 'default page size used if not specified (forward)' do
      uid = SecureRandom.uuid
      facade.publish_event(OrderCreated.new(order_id: 0))
      facade.publish_event(OrderCreated.new(event_id: uid, order_id: 1))
      (2..102).each do |index|
        facade.publish_event(OrderCreated.new(order_id: index), SecureRandom.uuid)
      end
      response = facade.read_all_streams_forward(uid)
      expect(response.length).to eq 100
      expect(response.map(&:order_id)).to eq (2..101).to_a
    end

    specify 'default page size used if not specified (backward)' do
      uid = SecureRandom.uuid
      (1..102).each do |index|
        facade.publish_event(OrderCreated.new(order_id: index), SecureRandom.uuid)
      end
      facade.publish_event(OrderCreated.new(event_id: uid, order_id: 103))
      facade.publish_event(OrderCreated.new(order_id: 104), SecureRandom.uuid)
      response = facade.read_all_streams_backward(uid)
      expect(response.length).to eq 100
      expect(response.map(&:order_id)).to eq (3..102).to_a.reverse
    end

    specify 'defaults used if nothing specified (forward)' do
      facade.publish_event(OrderCreated.new(order_id: 1))
      (2..102).each do |index|
        facade.publish_event(OrderCreated.new(order_id: index), SecureRandom.uuid)
      end
      response = facade.read_all_streams_forward
      expect(response.length).to eq 100
      expect(response.map(&:order_id)).to eq (1..100).to_a
    end

    specify 'defaults used if nothing specified (backward)' do
      (1..102).each do |index|
        facade.publish_event(OrderCreated.new(order_id: index), SecureRandom.uuid)
      end
      facade.publish_event(OrderCreated.new(order_id: 103))
      response = facade.read_all_streams_backward
      expect(response.length).to eq 100
      expect(response.map(&:order_id)).to eq (4..103).to_a.reverse
    end
  end
end
