# frozen_string_literal: true

require "spec_helper"
require "logger"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe Relay do
      let(:outbox) { double(:outbox) }
      let(:client) { double(:client, outbox: outbox) }
      let(:logger) { double(:logger, info: nil, error: nil) }

      def build_relay(**overrides)
        Relay.new(client: client, logger: logger, **overrides)
      end

      def result(claimed)
        Relay::BatchResult.new(claimed: claimed, delivered: claimed, retried: 0, dead: 0)
      end

      describe "#initialize" do
        specify "stores every given collaborator and setting in its own instance variable" do
          retry_policy = double(:retry_policy)
          clock = -> {}

          relay =
            Relay.new(
              client: client,
              batch_size: 42,
              poll_interval: 7,
              lease_duration: 9,
              retry_policy: retry_policy,
              clock: clock,
              logger: logger,
            )

          expect(relay.instance_variable_get(:@client)).to equal(client)
          expect(relay.instance_variable_get(:@batch_size)).to eq(42)
          expect(relay.instance_variable_get(:@poll_interval)).to eq(7)
          expect(relay.instance_variable_get(:@lease_duration)).to eq(9)
          expect(relay.instance_variable_get(:@retry_policy)).to equal(retry_policy)
          expect(relay.instance_variable_get(:@clock)).to equal(clock)
          expect(relay.instance_variable_get(:@logger)).to equal(logger)
          expect(relay.instance_variable_get(:@shutting_down)).to eq(false)
        end

        specify "defaults to a batch of 100, one second polling, a five minute lease and the standard retry policy" do
          relay = Relay.new(client: client)

          expect(relay.instance_variable_get(:@batch_size)).to eq(100)
          expect(relay.instance_variable_get(:@poll_interval)).to eq(1)
          expect(relay.instance_variable_get(:@lease_duration)).to eq(300)
          expect(relay.instance_variable_get(:@retry_policy)).to be_a(RetryPolicy)
          expect(relay.instance_variable_get(:@logger).instance_variable_get(:@logdev).dev).to equal($stdout)
          expect(relay.instance_variable_get(:@clock).call).to be_within(5).of(Time.now.utc)
          expect(relay.instance_variable_get(:@clock).call).to be_utc
        end
      end

      describe "#process_batch" do
        specify "claims batch_size messages leased for lease_duration from now, and delivers nothing when none are due" do
          now = Time.utc(2026, 9, 29, 12)
          allow(outbox).to receive(:claim).and_return([])
          relay = build_relay(batch_size: 7, lease_duration: 90, clock: -> { now })

          result = relay.process_batch

          expect(outbox).to have_received(:claim).with(7, now: now, lease_until: now + 90)
          expect(result).to eq(Relay::BatchResult.empty)
        end
      end

      describe "#run" do
        specify "installs signal handlers, logs start/stop, and loops until shutting down, sleeping only when nothing was claimed" do
          relay = build_relay(poll_interval: 99)
          allow(relay).to receive(:install_signal_handlers)
          allow(relay).to receive(:sleep)
          calls = 0
          allow(relay).to receive(:process_batch_safely) do
            calls += 1
            relay.instance_variable_set(:@shutting_down, true) if calls == 3
            calls == 3 ? result(5) : Relay::BatchResult.empty
          end

          relay.run

          expect(relay).to have_received(:install_signal_handlers)
          expect(logger).to have_received(:info).with("Starting RubyEventStore::OutboxRelay")
          expect(logger).to have_received(:info).with("Gracefully shutting down")
          expect(relay).to have_received(:process_batch_safely).exactly(3).times
          expect(relay).to have_received(:sleep).with(99).twice
        end
      end

      describe "#process_batch_safely (private)" do
        specify "returns the batch result" do
          relay = build_relay
          allow(relay).to receive(:process_batch).and_return(result(2))

          expect(relay.send(:process_batch_safely)).to eq(result(2))
        end

        specify "logs a failing batch with the exception's class and message, and reports nothing claimed" do
          error_class =
            Class.new(StandardError) do
              def message = "custom message"
              def to_s = "not this one"
            end
          stub_const("BatchFailure", error_class)
          relay = build_relay
          allow(relay).to receive(:process_batch).and_raise(error_class)

          expect(relay.send(:process_batch_safely)).to eq(Relay::BatchResult.empty)
          expect(logger).to have_received(:error).with("Error while processing outbox batch: BatchFailure: custom message")
        end
      end
    end
  end
end
