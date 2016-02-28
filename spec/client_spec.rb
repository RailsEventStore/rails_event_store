require 'spec_helper'

module RailsEventStore
  describe Client do

    specify 'initialize proper adapter type' do
      client = Client.new
      expect(client.repository).to be_a Repositories::EventRepository
    end

    specify 'read_all_streams' do
      client = Client.new
      expect(client.read_all_streams).to eq({})

      OrderPlaced = Class.new(RailsEventStore::Event)
      client.publish_event(OrderPlaced.new)
      client.publish_event(OrderPlaced.new, "stream-1")
      client.publish_event(OrderPlaced.new, "stream-2")
      client.publish_event(OrderPlaced.new, "stream-2")

      actuals = client.read_all_streams
      expect(actuals["all"].count).to eq 1
      expect(actuals["stream-1"].count).to eq 1
      expect(actuals["stream-2"].count).to eq 2
    end
  end
end
