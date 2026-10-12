# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/outbox_relay/rails"
require "logger"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe RailsClient do
      helper = SpecHelper.new

      around { |example| helper.run_lifecycle { example.run } }

      specify "is a RailsEventStore::Client with the extension" do
        expect(RailsClient.superclass).to equal(RailsEventStore::Client)
        expect(RailsClient.ancestors.first(2)).to eq([RailsClient, ClientExtension])
      end

      specify "requiring it leaves RailsEventStore::Client alone" do
        expect(RailsEventStore::Client.ancestors).not_to include(ClientExtension)
        expect(RailsEventStore::Client.new).not_to respond_to(:subscribe_async)
      end

      specify "honors async_subscriptions: and outbox:, which RailsEventStore::Client's own #initialize doesn't know" do
        subscriptions = helper.sync_subscriptions
        outbox = Outbox.new

        client = RailsClient.new(async_subscriptions: subscriptions, outbox: outbox)

        expect(client.async_subscriptions).to equal(subscriptions)
        expect(client.outbox).to equal(outbox)
      end

      specify "passes the rest of the arguments on to RailsEventStore::Client" do
        client = RailsClient.new(repository: helper.repository, correlation_id_generator: -> { "fixed" })
        event = TestEvent.new

        client.publish(event)

        expect(client.read.event(event.event_id).metadata[:correlation_id]).to eq("fixed")
      end

      specify "builds the defaults when none are given" do
        client = RailsClient.new

        expect(client.async_subscriptions).to be_a(AsyncSubscriptions)
        expect(client.outbox).to be_a(Outbox)
      end

      specify "builds the defaults exactly once" do
        calls = 0
        client = RailsClient.allocate
        client.define_singleton_method(:default_async_subscriptions) do
          calls += 1
          super()
        end

        client.send(:initialize)

        expect(calls).to eq(1)
      end

      specify "publishes with messages and delivers them through the relay" do
        TestAsyncJob.reset!
        client = RailsClient.new(repository: helper.repository)
        client.subscribe_async(TestAsyncJob, to: [TestEvent])
        event = TestEvent.new

        client.publish(event)
        expect(TestAsyncJob.received).to be_empty
        Relay.new(client: client, logger: Logger.new(File::NULL)).process_batch

        expect(TestAsyncJob.received.map { |payload| payload.fetch("event_id") }).to eq([event.event_id])
      end
    end
  end
end
