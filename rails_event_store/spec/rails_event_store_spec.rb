require 'spec_helper'

RSpec.describe RailsEventStore do
  class MyAsyncHandler < ActiveJob::Base
    self.queue_adapter = :inline
    cattr_accessor :event, :event_store
    def perform(payload)
      self.class.event = self.class.event_store.load_event(**payload)
    end
  end

  specify 'default dispatcher can into ActiveJob' do
    expect(MyAsyncHandler.event).to eq(nil)
    client = RailsEventStore::Client.new
    MyAsyncHandler.event_store = client
    client.subscribe_to_all_events(MyAsyncHandler)
    client.publish_event(ev = RailsEventStore::Event.new)
    expect(MyAsyncHandler.event).to eq(ev)
  end
end
