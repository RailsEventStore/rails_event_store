require 'spec_helper'
require_relative '../../ruby_event_store/spec/mappers/events_pb'

class AsyncProtoHandler < ActiveJob::Base
  self.queue_adapter = :inline

  def perform(event)
    @@event = YAML.load(event)
  end

  def self.event
    @@event
  end
end

module RailsEventStore
  RSpec.describe Client do
    specify 'can handle protobuf event class instead of RubyEventStore::Event' do
      manually_migrate_columns_to_binary
      client = Client.new(
        mapper: RubyEventStore::Mappers::Protobuf.new,
      )
      client.subscribe(->(ev){@ev = ev}, to: [ResTesting::OrderCreated.descriptor.name])
      client.subscribe(AsyncProtoHandler, to: [ResTesting::OrderCreated.descriptor.name])

      event = RubyEventStore::Proto.new(
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        )
      )
      client.publish_event(event, stream_name: 'test')
      expect(client.read_event(event.event_id)).to eq(event)
      expect(client.read_stream_events_forward('test')).to eq([event])

      expect(@ev).to eq(event)
      expect(AsyncProtoHandler.event).to eq(event)
    end

    private

    def manually_migrate_columns_to_binary
      Class.new(ActiveRecord::Migration[4.2]) do
        def change
          change_column :event_store_events, :metadata, :binary, null: true
          change_column :event_store_events, :data, :binary, null: false
        end
      end.new.change
      RailsEventStoreActiveRecord::Event.connection.schema_cache.clear!
      RailsEventStoreActiveRecord::Event.reset_column_information
    end
  end

  RSpec.describe RubyEventStore::Proto do
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