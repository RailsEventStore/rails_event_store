require 'spec_helper'
require 'action_controller/railtie'

AsyncAdapterAvailable = Gem::Version.new(Rails::VERSION::STRING) > Gem::Version.new("5.0.0")
SimpleAdapter = AsyncAdapterAvailable ? :async : :inline

RSpec.describe RailsEventStore do
  class MyLovelyAsyncHandler < ActiveJob::Base
    self.queue_adapter = SimpleAdapter
    cattr_accessor :event

    def perform(payload)
      self.class.event = Rails.configuration.event_store.deserialize(payload)
    end
  end

  class HandlerWithHelper < ActiveJob::Base
    self.queue_adapter = SimpleAdapter
    cattr_accessor :event

    prepend RailsEventStore::AsyncHandler

    def perform(event)
      self.class.event = event
    end
  end

  class MetadataHandler < ActiveJob::Base
    self.queue_adapter = SimpleAdapter
    cattr_accessor :metadata

    prepend RailsEventStore::CorrelatedHandler
    prepend RailsEventStore::AsyncHandler

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
    expect(MyLovelyAsyncHandler.event).to eq(nil)
    event_store.subscribe_to_all_events(MyLovelyAsyncHandler)
    event_store.publish_event(ev = RailsEventStore::Event.new)
    wait_until{ MyLovelyAsyncHandler.event }
    expect(MyLovelyAsyncHandler.event).to eq(ev)
  end

  specify 'ActiveJob with AsyncHandler prepended' do
    expect(HandlerWithHelper.event).to eq(nil)
    event_store.subscribe_to_all_events(HandlerWithHelper)
    event_store.publish_event(ev = RailsEventStore::Event.new)
    wait_until{ HandlerWithHelper.event }
    expect(HandlerWithHelper.event).to eq(ev)
  end

  specify 'ActiveJob with CorrelatedHandler prepended' do
    MetadataHandler.metadata = nil
    event_store.subscribe_to_all_events(MetadataHandler)
    event_store.publish_event(ev = RailsEventStore::Event.new)
    wait_until{ MetadataHandler.metadata }
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
    wait_until{ MetadataHandler.metadata }
    expect(MetadataHandler.metadata).to eq({
      correlation_id: "COID",
      causation_id:   ev.event_id,
    })
  end

  private

  def wait_until(&block)
    Timeout.timeout(1) do
      loop do
        break if block.call
        sleep(0.001)
      end
    end
  end

end
