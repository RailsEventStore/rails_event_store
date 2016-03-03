require 'spec_helper'

module RailsEventStore
  describe Client do

    specify 'initialize proper adapter type' do
      client = Client.new
      expect(client.repository).to be_a Repositories::EventRepository
    end

    specify 'read_all_streams' do
      client = Client.new
      expect(client.read_all_streams).to eq([])

      OrderPlaced = Class.new(RailsEventStore::Event)
      client.publish_event(OrderPlaced.new(order_id: 1))
      client.publish_event(OrderPlaced.new(order_id: 2), "stream-1")
      client.publish_event(OrderPlaced.new(order_id: 3), "stream-2")
      client.publish_event(OrderPlaced.new(order_id: 4), "stream-2")

      actuals = client.read_all_streams
      expect(actuals.count).to eq 4
      expect(actuals.map(&:order_id)).to eq [1,2,3,4]
    end
  end
end
