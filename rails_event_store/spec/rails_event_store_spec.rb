require 'spec_helper'

RSpec.describe RailsEventStore do
  class MyAsyncHandler < ActiveJob::Base
    self.queue_adapter = :inline
    cattr_accessor :event
    def perform(ev)
      self.class.event = YAML.load(ev)
    end
  end

  specify 'default dispatcher can into ActiveJob' do
    expect(MyAsyncHandler.event).to eq(nil)
    client = RailsEventStore::Client.new
    client.subscribe_to_all_events(MyAsyncHandler)
    client.publish_event(ev = RailsEventStore::Event.new)
    expect(MyAsyncHandler.event).to eq(ev)
  end
end
