require 'spec_helper'

class AsyncProtoHandler < ActiveJob::Base
  self.queue_adapter = :inline

  cattr_accessor :event_store

  def perform(payload)
    @@event = self.class.event_store.deserialize(serializer: RubyEventStore::NULL, **payload)
  end

  def self.event
    @@event
  end
end

module RailsEventStore
  RSpec.describe Client do
    include ProtobufHelper

    before(:each) { require_protobuf_dependencies }

    specify 'can handle protobuf event class instead of RubyEventStore::Event' do
      client = Client.new(
        mapper: RubyEventStore::Mappers::Protobuf.new,
        dispatcher: RubyEventStore::ComposedDispatcher.new(
          RubyEventStore::ImmediateAsyncDispatcher.new(scheduler: ActiveJobScheduler.new(serializer: RubyEventStore::NULL)),
          RubyEventStore::Dispatcher.new,
        ),
      )
      client.subscribe(->(ev){@ev = ev}, to: [ResTesting::OrderCreated.descriptor.name])
      client.subscribe(AsyncProtoHandler, to: [ResTesting::OrderCreated.descriptor.name])
      AsyncProtoHandler.event_store = client

      event = RubyEventStore::Proto.new(
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        )
      )
      client.publish(event, stream_name: 'test')
      expect(client.read.event(event.event_id)).to eq(event)
      expect(client.read.stream('test').to_a).to eq([event])

      expect(@ev).to eq(event)
      expect(AsyncProtoHandler.event).to eq(event)
    end
  end

  RSpec.describe RubyEventStore::Proto do
    include ProtobufHelper

    before(:each) { require_protobuf_dependencies }

    specify "equality" do
      event1 = RubyEventStore::Proto.new(
        event_id: "40a09ed1-e72f-4cbf-9b34-f28bc4e129bc",
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        )
      )
      event2 = RubyEventStore::Proto.new(
        event_id: "40a09ed1-e72f-4cbf-9b34-f28bc4e129bc",
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        )
      )
      # expect(event1.data).to eql(event2.data)
      expect(event1.data).to eq(event2.data)
      expect(event1).to eq(event2)
    end
  end
end
