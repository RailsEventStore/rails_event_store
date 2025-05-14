# frozen_string_literal: true

require "spec_helper"
require "rails_event_store"

class AsyncProtoHandler < ActiveJob::Base
  self.queue_adapter = :inline

  cattr_accessor :event_store

  def perform(payload)
    @@event =
      self.class.event_store.deserialize(
        serializer: RubyEventStore::NULL,
        **payload.transform_keys(&:to_sym)
      )
  end

  def self.event
    @@event
  end
end

module RubyEventStore
  ::RSpec.describe Client do
    include ProtobufHelper

    around(:each) do |example|
      ActiveJob::Base.with(logger: nil) { example.run }
    end

    specify "can handle protobuf event class instead of Event" do
      client =
        Client.new(
          mapper: Protobuf::Mappers::Protobuf.new,
          dispatcher:
            ComposedDispatcher.new(
              ImmediateAsyncDispatcher.new(
                scheduler:
                  RailsEventStore::ActiveJobScheduler.new(serializer: NULL)
              ),
              Dispatcher.new
            )
        )
      client.subscribe(
        ->(ev) { @ev = ev },
        to: [ResTesting::OrderCreated.descriptor.name]
      )
      client.subscribe(
        AsyncProtoHandler,
        to: [ResTesting::OrderCreated.descriptor.name]
      )
      AsyncProtoHandler.event_store = client

      event =
        Protobuf::Proto.new(
          data:
            ResTesting::OrderCreated.new(customer_id: 123, order_id: "K3THNX9")
        )
      client.publish(event, stream_name: "test")
      expect(client.read.event(event.event_id)).to eq(event)
      expect(client.read.stream("test").to_a).to eq([event])

      expect(@ev).to eq(event)
      expect(AsyncProtoHandler.event).to eq(event)
    end
  end

  ::RSpec.describe Protobuf::Proto do
    include ProtobufHelper

    specify "equality" do
      event1 =
        Protobuf::Proto.new(
          event_id: "40a09ed1-e72f-4cbf-9b34-f28bc4e129bc",
          data:
            ResTesting::OrderCreated.new(customer_id: 123, order_id: "K3THNX9")
        )
      event2 =
        Protobuf::Proto.new(
          event_id: "40a09ed1-e72f-4cbf-9b34-f28bc4e129bc",
          data:
            ResTesting::OrderCreated.new(customer_id: 123, order_id: "K3THNX9")
        )

      expect(event1.data).to eq(event2.data)
      expect(event1).to eq(event2)
    end
  end
end
