require 'spec_helper'

RSpec.describe RailsEventStore do
  after :each do
    RailsEventStore.event_repository = RailsEventStoreActiveRecord::EventRepository.new
  end

  it { expect(RailsEventStore.event_repository).to be_instance_of(RailsEventStoreActiveRecord::EventRepository) }

  describe '.adapter=' do
    it { expect{ RailsEventStore.event_repository = nil }.to raise_error(ArgumentError) }

    it 'when passing an object' do
      adapter = Object.new
      RailsEventStore::event_repository = adapter

      expect(RailsEventStore::event_repository).to eq adapter
    end
  end

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
