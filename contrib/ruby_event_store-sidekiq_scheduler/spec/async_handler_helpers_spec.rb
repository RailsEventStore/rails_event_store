require "spec_helper"
require "ruby_event_store/active_record"
require "rails_event_store"
require "rails"
require_relative "../../../support/helpers/silence_stdout"
require_relative "../../../support/helpers/migrator"

SilenceStdout.silence_stdout { require "sidekiq/testing" }

module RubyEventStore
  class SidekiqHandlerWithHelper
    include Sidekiq::Worker

    def perform(event)
      $queue.push(event)
    end
  end

  ::RSpec.describe RailsEventStore::AsyncHandler do
    let(:event_store) { RailsEventStore::Client.new }
    let(:application) { instance_double(Rails::Application) }
    let(:config) { FakeConfiguration.new }

    before do
      ::ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
      m =
        Migrator.new(
          File.expand_path(
            "../../../ruby_event_store-active_record/lib/ruby_event_store/active_record/generators/templates",
            __dir__
          )
        )
      SilenceStdout.silence_stdout { m.run_migration("create_event_store_events") }
      allow(Rails).to receive(:application).and_return(application)
      allow(application).to receive(:config).and_return(config)
      Rails.configuration.event_store = event_store
      ActiveJob::Base.queue_adapter = :async
      $queue = RubyEventStore::Queue.new
    end

    specify "Sidekiq::Worker without ActiveJob that requires serialization" do
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
  end

  private

  class FakeConfiguration
    def initialize
      @options = {}
    end

    private

    def method_missing(name, *args, &blk)
      if name.to_s =~ /=$/
        @options[$`.to_sym] = args.first
      end
    end
  end
end

