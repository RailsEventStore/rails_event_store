require "spec_helper"
require "rails_event_store"

SilenceStdout.silence_stdout { require "sidekiq/testing" }

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
        dispatcher:
          ImmediateAsyncDispatcher.new(
            scheduler: SidekiqScheduler.new(serializer: serializer)
          )
      )
    end
    let(:event) { RubyEventStore::Event.new }
    let(:serializer) { JSON }

    specify "integration with RailsEventStore::AsyncHandler helper" do
      $queue = Queue.new

      SidekiqHandlerWithHelper.prepend(
        RailsEventStore::AsyncHandler.with(
          event_store: event_store,
          serializer: serializer
        )
      )
      event_store.subscribe_to_all_events(SidekiqHandlerWithHelper)
      event_store.publish(event)
      Sidekiq::Worker.drain_all

      expect($queue.pop).to eq(event)
    end
  end
end
