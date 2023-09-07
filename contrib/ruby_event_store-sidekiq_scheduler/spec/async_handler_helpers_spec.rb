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
      prepare_database_schema
      $queue = Queue.new

      event_store =
        RailsEventStore::Client.new(
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

    def prepare_database_schema
      ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
      m =
        Migrator.new(
          File.expand_path(
            "../../../ruby_event_store-active_record/lib/ruby_event_store/active_record/generators/templates",
            __dir__
          )
        )
      SilenceStdout.silence_stdout { m.run_migration("create_event_store_events") }
    end
  end
end

