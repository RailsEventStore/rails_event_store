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

  ::RSpec.describe RailsEventStore::AsyncHandler do
    let(:event_store) do
      RubyEventStore::Client.new(
        dispatcher:
          ImmediateAsyncDispatcher.new(
            scheduler: SidekiqScheduler.new(serializer: YAML)
          )
      )
    end
    let(:event) { RubyEventStore::Event.new }

    specify "Sidekiq::Worker without ActiveJob that requires serialization" do
      $queue = Queue.new

      SidekiqHandlerWithHelper.prepend(
        RailsEventStore::AsyncHandler.with(
          event_store: event_store,
          serializer: YAML
        )
      )
      event_store.subscribe_to_all_events(SidekiqHandlerWithHelper)
      event_store.publish(event)
      Thread.new { Sidekiq::Worker.drain_all }.join

      expect($queue.pop).to eq(event)
    end
  end
end
