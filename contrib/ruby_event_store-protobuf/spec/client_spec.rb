# frozen_string_literal: true

require "spec_helper"
require "time"
require "json"

module RubyEventStore
  ::RSpec.describe Client do
    specify "can handle protobuf event class instead of RubyEventStore::Event" do
      client = RubyEventStore::Client.new(mapper: RubyEventStore::Protobuf::Mappers::Protobuf.new)
      event =
        RubyEventStore::Protobuf::Proto.new(
          event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
          data: ResTesting::OrderCreated.new(customer_id: 123, order_id: "K3THNX9"),
        )
      client.publish(event, stream_name: "test")

      expect(client.read.event!(event.event_id)).to eq(event)
      expect(client.read.stream("test").to_a).to eq([event])
    end

    specify "can load serialized event using Protobuf mapper" do
      client = RubyEventStore::Client.new(mapper: RubyEventStore::Protobuf::Mappers::Protobuf.new)
      event =
        TimeEnrichment.with(
          RubyEventStore::Protobuf::Proto.new(
            event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
            data: ResTesting::OrderCreated.new(customer_id: 123, order_id: "K3THNX9"),
            metadata: {
              time: Time.new(2018, 12, 13, 11),
            },
          ),
          timestamp: Time.utc(2019, 9, 30),
          valid_at: Time.utc(2019, 9, 30),
        )
      payload = {
        event_type: "res_testing.OrderCreated",
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        data: "\n\aK3THNX9\x10{",
        metadata: "\n\x10\n\x04time\x12\b:\x06\b\xA0\xDB\xC8\xE0\x05",
        timestamp: "2019-09-30T00:00:00.000000Z",
        valid_at: "2019-09-30T00:00:00.000000Z",
      }
      expect(client.deserialize(serializer: NULL, **payload)).to eq(event)
    end
  end
end
