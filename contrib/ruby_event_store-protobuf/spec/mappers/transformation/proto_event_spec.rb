# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Protobuf
    module Mappers
      module Transformation
        ::RSpec.describe ProtoEvent do
          include ProtobufHelper

          let(:time) { Time.now.utc }
          let(:uuid) { SecureRandom.uuid }
          let(:event) do
            TestEvent.new(
              event_id: uuid,
              data: {
                some: "value"
              },
              metadata: {
                some: "meta",
                timestamp: time,
                valid_at: time
              }
            )
          end
          let(:record) do
            Record.new(
              event_id: uuid,
              metadata: {
                some: "meta"
              },
              data:
                ResTesting::OrderCreated.new(
                  customer_id: 123,
                  order_id: "K3THNX9"
                ),
              event_type: "res_testing.OrderCreated",
              timestamp: time,
              valid_at: time
            )
          end

          specify "#load" do
            loaded = ProtoEvent.new.load(record)
            expect(loaded).to be_a(Proto)
            expect(loaded.event_id).to eq(uuid)
            expect(loaded.data).to be_a(ResTesting::OrderCreated)
            expect(loaded.metadata.to_h).to eq(event.metadata.to_h)
            expect(loaded.metadata[:timestamp]).to eq(time)
            expect(loaded.metadata[:valid_at]).to eq(time)
          end
        end
      end
    end
  end
end
