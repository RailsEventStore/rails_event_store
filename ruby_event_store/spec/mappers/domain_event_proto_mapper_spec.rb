require 'spec_helper'

module RubyEventStore
  module Mappers
    RSpec.describe DomainEventProtoMapper do
      include ProtobufHelper
      before(:each) { require_protobuf_dependencies }

      let(:uuid)  { SecureRandom.uuid }
      let(:event) {
        TestEvent.new(event_id: uuid,
                      data: {some: 'value'},
                      metadata: {some: 'meta'})
      }
      let(:item)  {
        TransformationItem.new(
          event_id:   uuid,
          metadata:   {some: 'meta'},
          data:       ResTesting::OrderCreated.new(customer_id: 123, order_id: 'K3THNX9'),
          event_type: 'res_testing.OrderCreated',
        )
      }

      specify "#load" do
        loaded = DomainEventProtoMapper.new.load(item)
        expect(loaded).to be_a(Proto)
        expect(loaded.event_id).to eq(uuid)
        expect(loaded.data).to be_a(ResTesting::OrderCreated)
        expect(loaded.metadata.to_h).to eq(event.metadata.to_h)
      end
    end
  end
end
