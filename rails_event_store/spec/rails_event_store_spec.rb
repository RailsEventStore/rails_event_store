require 'spec_helper'
require 'action_controller/railtie'

RSpec.describe RailsEventStore do
  class MyAsyncHandler < ActiveJob::Base
    self.queue_adapter = :inline
    cattr_accessor :event, :event_store
    def perform(payload)
      self.class.event = Rails.configuration.event_store.deserialize(payload)
    end
  end

  class HandlerWithHelper < ActiveJob::Base
    self.queue_adapter = :inline
    cattr_accessor :event

    prepend AsyncHandler

    def perform(event)
      self.class.event = event
    end
  end

  class MetadataHandler < ActiveJob::Base
    self.queue_adapter = :inline
    cattr_accessor :metadata

    prepend CorrelatedHandler
    prepend AsyncHandler

    def perform(event)
      self.metadata = Rails.configuration.event_store.metadata
    end
  end

  let(:event_store) { RailsEventStore::Client.new }

  before do
    rails = double("Rails", configuration: Rails::Application::Configuration.new)
    stub_const("Rails", rails)
    Rails.configuration.event_store = event_store
  end

  specify 'default dispatcher can into ActiveJob' do
    expect(MyAsyncHandler.event).to eq(nil)
    event_store.subscribe_to_all_events(MyAsyncHandler)
    event_store.publish_event(ev = RailsEventStore::Event.new)
    expect(MyAsyncHandler.event).to eq(ev)
  end

  specify 'ActiveJob with AsyncHandler prepended' do
    expect(HandlerWithHelper.event).to eq(nil)
    event_store.subscribe_to_all_events(HandlerWithHelper)
    event_store.publish_event(ev = RailsEventStore::Event.new)
    expect(HandlerWithHelper.event).to eq(ev)
  end

  specify 'ActiveJob with CorrelatedHandler prepended' do
    MetadataHandler.metadata = nil
    event_store.subscribe_to_all_events(MetadataHandler)
    event_store.publish_event(ev = RailsEventStore::Event.new)
    expect(MetadataHandler.metadata).to eq({
      correlation_id: ev.event_id,
      causation_id:   ev.event_id,
    })
  end

  specify 'ActiveJob with CorrelatedHandler prepended (2)' do
    MetadataHandler.metadata = nil
    event_store.subscribe_to_all_events(MetadataHandler)
    event_store.publish_event(ev = RailsEventStore::Event.new(
      metadata: {
        correlation_id: "COID",
        causation_id:   "CAID",
      }
    ))
    expect(MetadataHandler.metadata).to eq({
      correlation_id: "COID",
      causation_id:   ev.event_id,
    })
  end
end
