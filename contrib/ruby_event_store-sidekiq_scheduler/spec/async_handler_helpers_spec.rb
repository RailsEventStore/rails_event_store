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
    specify "Sidekiq::Worker without ActiveJob that requires serialization" do
      $queue = Queue.new

      event_store =
        RubyEventStore::Client.new(
          dispatcher: ImmediateAsyncDispatcher.new(scheduler: SidekiqScheduler.new(serializer: YAML))
        )
      ev = RubyEventStore::Event.new
      Sidekiq::Testing.fake! do
        SidekiqHandlerWithHelper.prepend RailsEventStore::AsyncHandler.with(
          event_store: event_store,
          serializer: YAML
        )
        event_store.subscribe_to_all_events(SidekiqHandlerWithHelper)
        event_store.publish(ev)
        Thread.new { Sidekiq::Worker.drain_all }.join
      end

      expect($queue.pop).to eq(ev)
    end
  end
end

