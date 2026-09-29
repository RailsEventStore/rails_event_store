# frozen_string_literal: true

require "spec_helper"
require "logger"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe Relay do
      let(:outbox) { double(:outbox) }
      let(:subscriptions) { double(:subscriptions, to_h: {}) }
      let(:client) { double(:client, outbox: outbox, async_subscriptions: subscriptions) }
      let(:logger) { double(:logger, info: nil, warn: nil, error: nil, debug: nil) }
      let(:instrumentation) { double(:instrumentation, instrument: nil) }

      def build_relay(**overrides)
        Relay.new(client: client, logger: logger, stats_interval: nil, **overrides)
      end

      def result(claimed)
        Relay::BatchResult.new(claimed: claimed, delivered: claimed, retried: 0, dead: 0, unrecorded: 0)
      end

      describe "#initialize" do
        specify "stores every given collaborator and setting in its own instance variable" do
          retry_policy = double(:retry_policy)
          clock = -> {}
          signals = double(:signals)
          instrumentation = double(:instrumentation)

          relay =
            Relay.new(
              client: client,
              batch_size: 42,
              poll_interval: 7,
              lease_duration: 9,
              retry_policy: retry_policy,
              clock: clock,
              signals: signals,
              instrumentation: instrumentation,
              stats_interval: 12,
              logger: logger,
            )

          expect(relay.instance_variable_get(:@client)).to equal(client)
          expect(relay.instance_variable_get(:@batch_size)).to eq(42)
          expect(relay.instance_variable_get(:@poll_interval)).to eq(7)
          expect(relay.instance_variable_get(:@lease_duration)).to eq(9)
          expect(relay.instance_variable_get(:@retry_policy)).to equal(retry_policy)
          expect(relay.instance_variable_get(:@clock)).to equal(clock)
          expect(relay.instance_variable_get(:@signals)).to equal(signals)
          expect(relay.instance_variable_get(:@instrumentation)).to equal(instrumentation)
          expect(relay.instance_variable_get(:@stats_interval)).to eq(12)
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
          expect(relay.instance_variable_get(:@signals)).to equal(Signal)
          expect(relay.instance_variable_get(:@instrumentation)).to equal(ActiveSupport::Notifications)
          expect(relay.instance_variable_get(:@stats_interval)).to eq(30)
        end

        specify "rejects a client that isn't extended with ClientExtension, saying what to use instead" do
          plain = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)

          expect { Relay.new(client: plain, logger: logger) }.to raise_error(
            ArgumentError,
            "client must be extended with RubyEventStore::OutboxRelay::ClientExtension, " \
              "e.g. an OutboxRelay::Client or a RailsClient, got RubyEventStore::Client",
          )
        end

        specify "needs both the outbox and the async subscriptions of the client" do
          expect { Relay.new(client: double(:client, outbox: outbox), logger: logger) }.to raise_error(ArgumentError)
          expect { Relay.new(client: double(:client, async_subscriptions: subscriptions), logger: logger) }.to raise_error(ArgumentError)
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

        specify "is instrumented, with the counts of the batch added to the payload" do
          allow(outbox).to receive(:claim).and_return([])
          payloads = []
          instrumentation = double(:instrumentation)
          allow(instrumentation).to receive(:instrument) do |name, payload, &block|
            payloads << [name, payload]
            block.call(payload)
          end
          relay = build_relay(instrumentation: instrumentation)

          result = relay.process_batch

          expect(result).to eq(Relay::BatchResult.empty)
          expect(payloads).to eq(
            [["process_batch.outbox_relay.ruby_event_store", { claimed: 0, delivered: 0, retried: 0, dead: 0, unrecorded: 0 }]],
          )
        end

        specify "leaves the failure of a batch to the instrumentation, which records it, and to the caller" do
          allow(outbox).to receive(:claim).and_raise(ArgumentError, "boom")

          expect { build_relay.process_batch }.to raise_error(ArgumentError, "boom")
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

        specify "logs the async subscribers of every topic" do
          allow(subscriptions).to receive(:to_h).and_return("OrderPlaced" => %w[Report Mailer], "OrderCancelled" => ["Refund"])
          relay = build_relay
          allow(relay).to receive(:install_signal_handlers)
          allow(relay).to receive(:process_batch_safely) do
            relay.instance_variable_set(:@shutting_down, true)
            Relay::BatchResult.empty
          end
          allow(relay).to receive(:sleep)

          relay.run

          expect(logger).to have_received(:info).with("Async subscribers of OrderPlaced: Report, Mailer")
          expect(logger).to have_received(:info).with("Async subscribers of OrderCancelled: Refund")
          expect(logger).not_to have_received(:warn)
        end

        specify "warns when no async subscriber is registered, since every message would be dead-lettered" do
          relay = build_relay
          allow(relay).to receive(:install_signal_handlers)
          allow(relay).to receive(:process_batch_safely) do
            relay.instance_variable_set(:@shutting_down, true)
            Relay::BatchResult.empty
          end
          allow(relay).to receive(:sleep)

          relay.run

          expect(logger).to have_received(:warn).with("No async subscribers registered: every message will fail as unknown, and be retried until it is dead-lettered")
        end

        specify "logs each batch that claimed something, at debug level" do
          relay = build_relay
          allow(relay).to receive(:install_signal_handlers)
          batches = [Relay::BatchResult.new(claimed: 5, delivered: 3, retried: 1, dead: 1, unrecorded: 2), Relay::BatchResult.empty]
          allow(relay).to receive(:process_batch_safely) do
            relay.instance_variable_set(:@shutting_down, true) if batches.size == 1
            batches.shift
          end
          allow(relay).to receive(:sleep)

          relay.run

          expect(logger).to have_received(:debug).with("Batch: claimed=5 delivered=3 retried=1 dead=1 unrecorded=2")
          expect(logger).to have_received(:debug).once
        end

        describe "stats" do
          let(:now) { Time.utc(2026, 9, 29, 12) }
          let(:stats) { Outbox::Stats.new(backlog: 3, oldest_due_age: 4.5, dead_letters: 1) }
          let(:published) { [] }
          let(:instrumentation) do
            published = self.published
            double(:instrumentation).tap { |i| allow(i).to receive(:instrument) { |name, payload| published << [name, payload] } }
          end

          def run_loops(relay, count)
            allow(relay).to receive(:install_signal_handlers)
            allow(relay).to receive(:sleep)
            calls = 0
            allow(relay).to receive(:process_batch_safely) do
              calls += 1
              relay.instance_variable_set(:@shutting_down, true) if calls == count
              Relay::BatchResult.empty
            end
            relay.run
          end

          specify "are published after the first batch, then once every stats_interval" do
            allow(outbox).to receive(:stats) { |now:| stats }
            times = [now, now + 10, now + 29, now + 30, now + 45].each
            relay = build_relay(instrumentation: instrumentation, stats_interval: 30, clock: -> { times.next })

            run_loops(relay, 5)

            expect(published.map(&:first)).to eq(["stats.outbox_relay.ruby_event_store"] * 2)
            expect(published.first.last).to eq(backlog: 3, oldest_due_age: 4.5, dead_letters: 1)
            expect(outbox).to have_received(:stats).with(now: now)
            expect(outbox).to have_received(:stats).with(now: now + 30)
          end

          specify "aren't published, nor computed, when stats_interval is nil" do
            allow(outbox).to receive(:stats)
            relay = build_relay(instrumentation: instrumentation, stats_interval: nil)

            run_loops(relay, 2)

            expect(published).to be_empty
            expect(outbox).not_to have_received(:stats)
          end

          specify "failing to be computed is logged by class, and doesn't stop the relay" do
            allow(outbox).to receive(:stats).and_raise(ArgumentError, "password=hunter2")
            relay = build_relay(instrumentation: instrumentation, stats_interval: 30)

            run_loops(relay, 2)

            expect(logger).to have_received(:error).with("Error while collecting outbox stats: ArgumentError").at_least(:once)
            expect(logger).not_to have_received(:error).with(a_string_including("hunter2"))
            expect(published).to be_empty
          end
        end
      end

      describe "#process_batch_safely (private)" do
        specify "returns the batch result" do
          relay = build_relay
          allow(relay).to receive(:process_batch).and_return(result(2))

          expect(relay.send(:process_batch_safely)).to eq(result(2))
        end

        specify "logs a failing batch by its class only, keeping the message and backtrace for debug, and reports nothing claimed" do
          error = ArgumentError.new("password=hunter2")
          error.set_backtrace(Array.new(15) { |i| "line #{i}" })
          relay = build_relay
          allow(relay).to receive(:process_batch).and_raise(error)

          expect(relay.send(:process_batch_safely)).to eq(Relay::BatchResult.empty)
          expect(logger).to have_received(:error).with("Error while processing outbox batch: ArgumentError")
          expect(logger).to have_received(:debug).with(
            "Outbox batch error detail: password=hunter2\n#{Array.new(10) { |i| "line #{i}" }.join("\n")}",
          )
        end

        specify "logs the exception's message, not its string form, for debug" do
          error_class =
            Class.new(StandardError) do
              def message = "custom message"
              def to_s = "not this one"
            end
          relay = build_relay
          allow(relay).to receive(:process_batch).and_raise(error_class)

          relay.send(:process_batch_safely)

          expect(logger).to have_received(:debug).with(a_string_starting_with("Outbox batch error detail: custom message\n"))
        end

        specify "copes with an exception that has no backtrace" do
          error_class = Class.new(StandardError) { def backtrace = nil }
          relay = build_relay
          allow(relay).to receive(:process_batch).and_raise(error_class, "boom")

          relay.send(:process_batch_safely)

          expect(logger).to have_received(:debug).with("Outbox batch error detail: boom\n")
        end

        specify "never puts the exception's message in the error log" do
          relay = build_relay
          allow(relay).to receive(:process_batch).and_raise(ArgumentError, "password=hunter2")

          relay.send(:process_batch_safely)

          expect(logger).not_to have_received(:error).with(a_string_including("hunter2"))
        end
      end

      describe "#install_signal_handlers (private)" do
        around do |example|
          previous = %w[INT TERM].to_h { |signal| [signal, Signal.trap(signal, "DEFAULT")] }
          example.run
        ensure
          previous.each { |signal, handler| Signal.trap(signal, handler) }
        end

        def wait_until
          deadline = Time.now + 2
          sleep(0.01) until yield || Time.now > deadline
        end

        %w[INT TERM].each do |signal|
          specify "#{signal} requests a graceful shutdown" do
            relay = build_relay
            relay.send(:install_signal_handlers)

            Process.kill(signal, Process.pid)
            wait_until { relay.instance_variable_get(:@shutting_down) }

            expect(relay.instance_variable_get(:@shutting_down)).to eq(true)
          end

          specify "#{signal} still reaches the handler installed before, with the signal number" do
            received = []
            Signal.trap(signal) { |signo| received << signo }
            relay = build_relay
            relay.send(:install_signal_handlers)

            Process.kill(signal, Process.pid)
            wait_until { !received.empty? }

            expect(received).to eq([Signal.list.fetch(signal)])
            expect(relay.instance_variable_get(:@shutting_down)).to eq(true)
          end
        end

        specify "installs handlers for INT and TERM on the given signals, each shutting down when called" do
          signals = double(:signals)
          handlers = {}
          allow(signals).to receive(:trap) { |signal, &handler| handlers[signal] = handler; "DEFAULT" }
          relay = build_relay(signals: signals)

          relay.send(:install_signal_handlers)

          expect(handlers.keys).to eq(%w[INT TERM])
          handlers.each_value do |handler|
            relay.instance_variable_set(:@shutting_down, false)
            handler.call(2)
            expect(relay.instance_variable_get(:@shutting_down)).to eq(true)
          end
        end

        specify "a default handler that isn't callable is left alone" do
          relay = build_relay
          relay.send(:install_signal_handlers)

          expect { Process.kill("TERM", Process.pid) }.not_to raise_error
          wait_until { relay.instance_variable_get(:@shutting_down) }
        end
      end
    end
  end
end
