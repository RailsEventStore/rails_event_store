require 'spec_helper'

class AsyncProtoHandler < ActiveJob::Base
  self.queue_adapter = :inline

  cattr_accessor :event_store

  def perform(payload)
    @@event = self.class.event_store.deserialize(payload)
  end

  def self.event
    @@event
  end
end

module RailsEventStore
  RSpec.describe Client do
    before(:each) do
      begin
        require_relative '../../ruby_event_store/spec/mappers/events_pb'
      rescue LoadError => exc
        skip if exc.message == "cannot load such file -- google/protobuf_c"
      end
    end

    specify 'can handle protobuf event class instead of RubyEventStore::Event' do
      manually_migrate_columns_to_binary
      client = Client.new(
        mapper: RubyEventStore::Mappers::Protobuf.new,
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

    private

    def manually_migrate_columns_to_binary
      ActiveRecord::Migration.drop_table("event_store_events")
      ActiveRecord::Migration.drop_table("event_store_events_in_streams")
      m = Migrator.new(File.expand_path('../../rails_event_store_active_record/lib/rails_event_store_active_record/generators/templates', __dir__))
      binary = m.migration_code('create_event_store_events').gsub("text", "binary").gsub("CreateEventStoreEvents", "CreateEventStoreEventsBinary")
      eval(binary) unless defined?(CreateEventStoreEventsBinary)
      CreateEventStoreEventsBinary.new.change
      RailsEventStoreActiveRecord::Event.connection.schema_cache.clear!
      RailsEventStoreActiveRecord::Event.reset_column_information
    end
  end

  RSpec.describe RubyEventStore::Proto do
    before(:each) do
      begin
        require_relative '../../ruby_event_store/spec/mappers/events_pb'
      rescue LoadError => exc
        skip if exc.message == "cannot load such file -- google/protobuf_c"
      end
    end

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
