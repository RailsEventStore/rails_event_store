require 'spec_helper'
require_relative '../../ruby_event_store/spec/mappers/events_pb'

module RailsEventStore
  RSpec.describe Client do
    specify 'can handle protobuf event class instead of RubyEventStore::Event' do
      client = Client.new(repository: RailsEventStoreActiveRecord::EventRepository.new(
        mapper: RubyEventStore::Mappers::Protobuf.new,
      ))
      client.subscribe(->(ev){@ev = ev}, [ResTesting::OrderCreated])
      event = ResTesting::OrderCreated.new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        customer_id: 123,
        order_id: "K3THNX9",
      )
      client.publish_event(event, stream_name: 'test')
      expect(client.read_event(event.event_id)).to eq(event)
      expect(client.read_stream_events_forward('test')).to eq([event])
      expect(@ev).to equal(event)
    end
  end
end