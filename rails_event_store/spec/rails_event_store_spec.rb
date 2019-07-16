require 'spec_helper'
require 'action_controller/railtie'

$stdout = StringIO.new
require 'sidekiq/testing'
$stdout = STDOUT

AsyncAdapterAvailable = Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new("5.0.0")
SimpleAdapter = AsyncAdapterAvailable ? :async : :inline

RSpec.describe RailsEventStore do
  class MyLovelyAsyncHandler < ActiveJob::Base
    cattr_accessor :event

    def perform(payload)
      self.class.event = Rails.configuration.event_store.deserialize(payload)
    end
  end

  class SidekiqHandlerWithHelper
    include Sidekiq::Worker

    cattr_accessor :event

    prepend RailsEventStore::AsyncHandler

    def perform(event)
      self.class.event = event
    end
  end

  class HandlerWithHelper < ActiveJob::Base
    cattr_accessor :event

    prepend RailsEventStore::AsyncHandler

    def perform(event)
      self.class.event = event
    end
  end

  class MetadataHandler < ActiveJob::Base
    cattr_accessor :metadata

    prepend RailsEventStore::CorrelatedHandler
    prepend RailsEventStore::AsyncHandler

    def perform(_event)
      self.metadata = Rails.configuration.event_store.metadata
    end
  end

  class CustomSidekiqScheduler
    def call(klass, serialized_event)
      klass.perform_async(serialized_event.to_h)
    end

    def verify(subscriber)
      Class === subscriber && subscriber.respond_to?(:perform_async)
    end
  end

  let(:event_store) { RailsEventStore::Client.new }

  before do
    allow(Rails.configuration).to receive(:event_store).and_return(event_store)
    ActiveJob::Base.queue_adapter = SimpleAdapter
  end

  specify 'default dispatcher can into ActiveJob' do
    MyLovelyAsyncHandler.event = nil
    event_store.subscribe_to_all_events(MyLovelyAsyncHandler)
    event_store.publish(ev = RailsEventStore::Event.new)
    wait_until{ MyLovelyAsyncHandler.event }
    expect(MyLovelyAsyncHandler.event).to eq(ev)
  end

  specify 'ActiveJob with AsyncHandler prepended' do
    HandlerWithHelper.event = nil
    event_store.subscribe_to_all_events(HandlerWithHelper)
    event_store.publish(ev = RailsEventStore::Event.new)
    wait_until{ HandlerWithHelper.event }
    expect(HandlerWithHelper.event).to eq(ev)
  end

  specify 'ActiveJob with CorrelatedHandler prepended' do
    MetadataHandler.metadata = nil
    event_store.subscribe_to_all_events(MetadataHandler)
    event_store.publish(ev = RailsEventStore::Event.new)
    wait_until{ MetadataHandler.metadata }
    expect(MetadataHandler.metadata).to eq({
      correlation_id: ev.event_id,
      causation_id:   ev.event_id,
    })
  end

  specify 'ActiveJob with CorrelatedHandler prepended (2)' do
    MetadataHandler.metadata = nil
    event_store.subscribe_to_all_events(MetadataHandler)
    event_store.publish(ev = RailsEventStore::Event.new(
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

  specify 'ActiveJob with sidekiq adapter that requires serialization', mutant: false do
    ActiveJob::Base.queue_adapter = :sidekiq
    ev = RailsEventStore::Event.new
    Sidekiq::Testing.fake! do
      MyLovelyAsyncHandler.event = nil
      event_store.subscribe_to_all_events(MyLovelyAsyncHandler)
      event_store.publish(ev)
      Thread.new{ Sidekiq::Worker.drain_all }.join
    end
    expect(MyLovelyAsyncHandler.event).to eq(ev)
  end

  specify 'Sidekiq::Worker without ActiveJob that requires serialization' do
    event_store = RailsEventStore::Client.new(
      dispatcher: RubyEventStore::ImmediateAsyncDispatcher.new(scheduler: CustomSidekiqScheduler.new)
    )
    ev = RailsEventStore::Event.new
    Sidekiq::Testing.fake! do
      SidekiqHandlerWithHelper.event = nil
      event_store.subscribe_to_all_events(SidekiqHandlerWithHelper)
      event_store.publish(ev)
      Thread.new{ Sidekiq::Worker.drain_all }.join
    end
    expect(SidekiqHandlerWithHelper.event).to eq(ev)
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
