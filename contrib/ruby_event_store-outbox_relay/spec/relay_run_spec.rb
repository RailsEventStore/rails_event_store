# frozen_string_literal: true

require "spec_helper"
require "logger"
require "timeout"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe Relay, "running", mutant: false do
      helper = SpecHelper.new

      around { |example| helper.run_lifecycle { example.run } }

      around do |example|
        previous = %w[INT TERM].to_h { |signal| [signal, Signal.trap(signal, "DEFAULT")] }
        example.run
      ensure
        previous.each { |signal, handler| Signal.trap(signal, handler) }
      end

      let(:log) { StringIO.new }
      let(:client) { helper.extended_client_class.new(repository: helper.repository, async_subscriptions: helper.sync_subscriptions) }

      def run_until(relay)
        stopper =
          Thread.new do
            sleep(0.005) until yield
            Process.kill("TERM", Process.pid)
          end
        Timeout.timeout(15) { relay.run }
      ensure
        stopper&.kill
      end

      specify "delivers what was published, deletes it, and shuts down cleanly on TERM" do
        handler = recording_handler("OrderReport")
        client.subscribe_async(handler, to: [TestEvent])
        events = Array.new(3) { TestEvent.new }.each { |event| client.publish(event) }
        relay = Relay.new(client: client, poll_interval: 0.01, stats_interval: nil, logger: Logger.new(log))

        run_until(relay) { handler.received.size == 3 }

        expect(handler.received.map(&:event_id)).to eq(events.map(&:event_id))
        expect(Message.count).to eq(0)
        expect(log.string).to include("Starting RubyEventStore::OutboxRelay", "Async subscribers of TestEvent: OrderReport")
        expect(log.string).to end_with("Gracefully shutting down\n")
      end

      specify "picks up what is published while it runs, which it finds on a later poll" do
        first, second = TestEvent.new, TestEvent.new
        handler = recording_handler("OrderReport") { |event| client.publish(second) if event.event_id == first.event_id }
        client.subscribe_async(handler, to: [TestEvent])
        client.publish(first)
        relay = Relay.new(client: client, poll_interval: 0.01, stats_interval: nil, logger: Logger.new(log))

        run_until(relay) { handler.received.size == 2 }

        expect(handler.received.map(&:event_id)).to eq([first.event_id, second.event_id])
        expect(Message.count).to eq(0)
      end

      specify "retries a failing message with a backoff, and dead-letters it while delivering the others" do
        attempts = Hash.new(0)
        bad = TestEvent.new
        handler =
          recording_handler("OrderReport") do |event|
            attempts[event.event_id] += 1
            raise "boom" if event.event_id == bad.event_id
          end
        client.subscribe_async(handler, to: [TestEvent])
        good = [TestEvent.new, TestEvent.new]
        [good[0], bad, good[1]].each { |event| client.publish(event) }
        policy = RetryPolicy.new(max_attempts: 2, base_delay: 0.01, jitter: 0)
        relay = Relay.new(client: client, poll_interval: 0.01, retry_policy: policy, stats_interval: nil, logger: Logger.new(log))

        run_until(relay) { attempts[bad.event_id] == 2 && handler.received.size == 2 }

        expect(handler.received.map(&:event_id)).to eq(good.map(&:event_id))
        expect(Message.count).to eq(0)
        expect(DeadLetter.sole).to have_attributes(event_id: bad.event_id, attempts: 2, error_class: "RuntimeError")
        expect(log.string).to include("failed attempt 1/2", "moved to dead letters after 2 attempt(s)")
      end
    end
  end
end
