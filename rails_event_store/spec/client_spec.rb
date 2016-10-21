require 'spec_helper'

module RailsEventStore
  describe Client do
    specify 'initialize proper adapter type' do
      client = Client.new
      expect(client.__send__("repository")).to be_a RailsEventStoreActiveRecord::EventRepository
      expect(client.__send__("page_size")).to eq RailsEventStore::PAGE_SIZE
    end

    specify 'initialize proper event broker type' do
      client = Client.new
      expect(client.__send__("event_broker")).to be_a EventBroker
    end

    specify 'may take custom broker' do
      CustomEventBroker = Class.new
      client = Client.new(event_broker: CustomEventBroker.new)
      expect(client.__send__("event_broker")).to be_a CustomEventBroker
    end

    specify 'initialize custom page size' do
      client = Client.new(page_size: 222)
      expect(client.__send__("page_size")).to eq 222
    end
  end
end
