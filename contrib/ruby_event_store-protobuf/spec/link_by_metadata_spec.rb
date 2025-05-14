# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe LinkByMetadata do
    specify "links to stream based on selected metadata (proto)" do
      event_store =
        RubyEventStore::Client.new(
          mapper: RubyEventStore::Protobuf::Mappers::Protobuf.new
        )
      event_store.subscribe_to_all_events(
        LinkByMetadata.new(event_store: event_store, key: :city)
      )
      ev =
        RubyEventStore::Protobuf::Proto.new(
          data:
            ResTesting::OrderCreated.new(customer_id: 123, order_id: "K3THNX9"),
          metadata: {
            city: "Chicago"
          }
        )
      event_store.publish(ev)

      expect(event_store.read.stream("$by_city_Chicago").to_a).to eq([ev])
    end
  end
end
