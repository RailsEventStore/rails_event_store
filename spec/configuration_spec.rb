require 'spec_helper'

module RailsEventStore
  describe Client do

    specify 'initialize with defaults' do
      client = Client.new
      expect(client.__send__("repository")).to be_a RailsEventStoreActiveRecord::EventRepository
      expect(client.__send__("event_broker")).to be_a RailsEventStore::EventBroker
      expect(client.__send__("page_size")).to eq(100)
    end

    specify 'setup custom dependencies via configuration' do
      repository = double(:repository)
      broker = double(:broker)
      RailsEventStore.configure do |cfg|
        cfg.page_size = 10
        cfg.event_repository = repository
        cfg.event_broker = broker
      end
      client = Client.new
      expect(client.__send__("repository")).to eq(repository)
      expect(client.__send__("event_broker")).to eq(broker)
      expect(client.__send__("page_size")).to eq(10)
      RailsEventStore.reset
    end

    specify 'setup dependencies via constructor' do
      repository = double(:repository)
      broker = double(:broker)
      client = Client.new(
        page_size: 10,
        repository: repository,
        event_broker: broker,
      )
      expect(client.__send__("repository")).to eq(repository)
      expect(client.__send__("event_broker")).to eq(broker)
      expect(client.__send__("page_size")).to eq(10)
    end
  end
end
