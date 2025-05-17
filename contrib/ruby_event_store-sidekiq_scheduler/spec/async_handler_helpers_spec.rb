# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  class SidekiqHandlerWithHelper
    include Sidekiq::Worker

    def perform(event)
      $queue.push(event)
    end
  end

  ::RSpec.describe SidekiqScheduler do
    let(:event_store) do
      RubyEventStore::Client.new(
        message_broker:
          RubyEventStore::Broker.new(
            dispatcher: ImmediateAsyncDispatcher.new(scheduler: SidekiqScheduler.new(serializer: serializer)),
          ),
      )
    end
    let(:event) { RubyEventStore::Event.new }
    let(:serializer) { JSON }

    specify "integration with RailsEventStore::AsyncHandler helper" do
      $queue = Queue.new

      SidekiqHandlerWithHelper.prepend(
        RailsEventStore::AsyncHandler.with(event_store: event_store, serializer: serializer),
      )
      event_store.subscribe_to_all_events(SidekiqHandlerWithHelper)
      event_store.publish(event)
      perform_all_enqueued_jobs

      expect($queue.pop).to eq(event)
    end

    private

    def perform_all_enqueued_jobs
      Sidekiq::Worker.drain_all
    end
  end
end
