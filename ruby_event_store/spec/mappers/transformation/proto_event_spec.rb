require 'spec_helper'

module RubyEventStore
  module Mappers
    module Transformation
      RSpec.describe ProtoEvent do
        include ProtobufHelper
        before(:each) { require_protobuf_dependencies }

        let(:time)  { Time.now.utc }
        let(:uuid)  { SecureRandom.uuid }
        let(:event) {
          TestEvent.new(
            event_id: uuid,
            data: {some: 'value'},
            metadata: {some: 'meta', timestamp: time, valid_at: time}
          )
        }
        let(:record)  {
          Record.new(
            event_id:   uuid,
            metadata:   {some: 'meta'},
            data:       ResTesting::OrderCreated.new(customer_id: 123, order_id: 'K3THNX9'),
            event_type: 'res_testing.OrderCreated',
            timestamp:  time,
            valid_at:   time
          )
        }

        specify "#load" do
          loaded = ProtoEvent.new.load(record)
          expect(loaded).to be_a(Proto)
          expect(loaded.event_id).to eq(uuid)
          expect(loaded.data).to be_a(ResTesting::OrderCreated)
          expect(loaded.metadata.to_h).to eq(event.metadata.to_h)
          expect(loaded.timestamp).to eq(time)
          expect(loaded.valid_at).to eq(time)
        end
      end
    end
  end
end
