# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Scavenger
    ::RSpec.describe Runner do
      DAY = 24 * 3600

      let(:repository) { ActiveRecord::EventRepository.new(serializer: SpecHelper.serializer) }
      let(:strategy) { ActiveRecord::ScavengeStrategy.new }
      let(:client) { Client.new(repository: StreamMetadataAwareRepository.new(repository)) }
      let(:clock) { FakeClock.new }
      let(:state) { State.new(clock: clock) }
      let(:sleeper) { ->(seconds) { slept << seconds } }
      let(:slept) { [] }

      def runner(**options)
        Runner.new(
          repository: repository,
          strategy: strategy,
          state: state,
          clock: clock,
          sleeper: sleeper,
          allow_in_process: true,
          **options,
        )
      end

      def publish(stream_name, count)
        events = Array.new(count) { RubyEventStore::Event.new }
        client.publish(events, stream_name: stream_name, expected_version: :auto)
        events.map(&:event_id)
      end

      def read(stream_name)
        client.read.stream(stream_name).map(&:event_id)
      end

      def links(stream_name)
        ::ActiveRecord::Base.connection.select_value(
          "SELECT COUNT(*) FROM event_store_events_in_streams WHERE stream = '#{stream_name}'",
        )
      end

      def scavenged(stream_name)
        client.read.stream("$$#{stream_name}").of_type(StreamMetadataEvents::StreamScavenged).to_a
      end

      def subscribe(pattern)
        events = []
        subscriber = ActiveSupport::Notifications.subscribe(pattern) { |event| events << event }
        yield
        events
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      def writes
        statements = []
        callback = ->(*, payload) do
          statements << payload[:sql] if payload[:sql].match?(/\A\s*(INSERT|UPDATE|DELETE)/i)
        end
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
        statements
      end

      def sweep_day
        clock.advance(7 * DAY + 1)
      end

      describe "guard" do
        specify "refuses without RES_SCAVENGER and allow_in_process" do
          runner = Runner.new(repository: repository, strategy: strategy, env: {})

          expect { runner.call }.to raise_error(
            NotAllowed,
            "Set RES_SCAVENGER in the environment of the scavenger process or pass allow_in_process: true",
          )
          expect { runner.call(dry_run: false) }.to raise_error(NotAllowed)
        end

        specify "runs with RES_SCAVENGER in the environment" do
          runner = Runner.new(repository: repository, strategy: strategy, env: { "RES_SCAVENGER" => "" })

          expect(runner.call.outcome).to eq(:finished)
        end

        specify "runs with allow_in_process" do
          runner = Runner.new(repository: repository, strategy: strategy, env: {}, allow_in_process: true)

          expect(runner.call.outcome).to eq(:finished)
        end

        specify "reads ENV by default" do
          runner = Runner.new(repository: repository, strategy: strategy)

          expect { runner.call }.to raise_error(NotAllowed) unless ENV.key?("RES_SCAVENGER")
          ENV["RES_SCAVENGER"] = "1"
          expect(runner.call.outcome).to eq(:finished)
        ensure
          ENV.delete("RES_SCAVENGER")
        end

        specify "refuses a grace period shorter than 7 days without force" do
          expect { runner(grace_period: 7 * DAY - 1) }.to raise_error(
            GracePeriodTooShort,
            "A grace period shorter than 604800 seconds needs force",
          )
          expect { runner(grace_period: 0) }.to raise_error(GracePeriodTooShort)
        end

        specify "takes a grace period of 7 days and more" do
          expect { runner(grace_period: 7 * DAY) }.not_to raise_error
          expect { runner(grace_period: 30 * DAY) }.not_to raise_error
        end

        specify "takes a shorter grace period with force" do
          expect { runner(grace_period: 0, force: true) }.not_to raise_error
        end

        specify "refuses an unknown policy" do
          expect { runner(policy: :purge) }.to raise_error(InvalidPolicy)
        end

        specify "builds state and lock on the base class by default" do
          states = []
          allow(State).to receive(:new).and_wrap_original { |original, **options|
            original.call(**options).tap { |state| states << state }
          }
          allow(Lock).to receive(:new).and_call_original

          Runner.new(repository: repository, strategy: strategy, base: CustomApplicationRecord)

          expect(State).to have_received(:new).with(base: CustomApplicationRecord)
          expect(Lock).to have_received(:new).with(base: CustomApplicationRecord, state: states.first)
        end

        specify "default batch size" do
          expect(Runner::DEFAULT_BATCH_SIZE).to eq(1_000)
        end

        specify "default grace period" do
          expect(Runner::DEFAULT_GRACE_PERIOD).to eq(604_800)
        end
      end

      describe "dry run" do
        specify "is the default" do
          publish("Order$1", 5)
          client.set_stream_metadata("Order$1", max_count: 2)

          report = runner.call

          expect(report.dry_run).to be(true)
          expect(read("Order$1").size).to eq(5)
        end

        specify "reports what a run would mark and sweep" do
          publish("Order$1", 5)
          client.set_stream_metadata("Order$1", max_count: 2)
          publish("Order$2", 3)
          client.soft_delete_stream("Order$2")
          sweep_day

          report = runner.call

          expect(report).to eq(
            Report.new(
              policy: Policy.links_only,
              dry_run: true,
              outcome: :finished,
              streams: [
                Report::StreamResult.new(stream: Stream.new("Order$1"), reasons: [:max_count], marked: 3, swept: 0),
                Report::StreamResult.new(stream: Stream.new("Order$2"), reasons: [:soft_delete], marked: 0, swept: 2),
              ],
            ),
          )
        end

        specify "issues no INSERT, UPDATE or DELETE" do
          publish("Order$1", 5)
          client.set_stream_metadata("Order$1", max_count: 2)
          publish("Order$2", 3)
          client.soft_delete_stream("Order$2")
          sweep_day

          expect(writes { runner.call(dry_run: true) }).to eq([])
          expect(read("Order$1").size).to eq(5)
          expect(links("Order$2")).to eq(3)
        end

        specify "takes no lock and writes no status" do
          lock = instance_double(Lock)
          publish("Order$1", 2)
          client.set_stream_metadata("Order$1", max_count: 1)

          runner(lock: lock).call

          expect(state.status).to eq(Status.initial)
        end

        specify "starts from the first stream" do
          publish("a", 2)
          publish("b", 2)
          client.set_stream_metadata("a", max_count: 1)
          client.set_stream_metadata("b", max_count: 1)
          state.save(status: :idle, stream: nil, cursor: "a")

          expect(runner.call.streams.map(&:stream)).to eq([Stream.new("a"), Stream.new("b")])
        end

        specify "leaves out streams with nothing to do" do
          publish("a", 2)
          client.set_stream_metadata("a", max_count: 5)

          expect(runner.call.streams).to eq([])
        end
      end

      describe "run" do
        specify "marks what retention hides" do
          event_ids = publish("Order$1", 5)
          client.set_stream_metadata("Order$1", max_count: 2)

          report = runner.call(dry_run: false)

          expect(report).to eq(
            Report.new(
              policy: Policy.links_only,
              dry_run: false,
              outcome: :finished,
              streams: [
                Report::StreamResult.new(stream: Stream.new("Order$1"), reasons: [:max_count], marked: 3, swept: 0),
              ],
            ),
          )
          expect(read("Order$1")).to eq(event_ids.last(2))
          expect(links("Order$1")).to eq(5)
        end

        specify "marks by max_age from link time" do
          publish("Order$1", 3)
          client.set_stream_metadata("Order$1", max_age: 3600)

          expect(runner.call(dry_run: false).marked).to eq(0)
          clock.advance(3601)
          expect(runner.call(dry_run: false).marked).to eq(3)
          expect(read("Order$1")).to eq([])
        end

        specify "finishes an interrupted truncation" do
          publish("Order$1", 5)
          client.truncate_stream("Order$1", before: 3)
          ::ActiveRecord::Base.connection.execute("UPDATE event_store_events_in_streams SET truncated_at = NULL")

          expect(runner.call(dry_run: false).streams.map(&:reasons)).to eq([[:truncate_before]])
          expect(read("Order$1").size).to eq(2)
        end

        specify "sweeps entries hidden longer ago than the grace period" do
          publish("Order$1", 5)
          client.set_stream_metadata("Order$1", max_count: 2)
          runner.call(dry_run: false)

          clock.advance(7 * DAY)
          expect(runner.call(dry_run: false).swept).to eq(0)

          clock.advance(1)
          report = runner.call(dry_run: false)
          expect(report.swept).to eq(3)
          expect(report.streams).to eq(
            [Report::StreamResult.new(stream: Stream.new("Order$1"), reasons: [], marked: 0, swept: 3)],
          )
          expect(links("Order$1")).to eq(2)
        end

        specify "sweeps with the grace period given" do
          publish("Order$1", 3)
          client.set_stream_metadata("Order$1", max_count: 1)
          runner.call(dry_run: false)
          clock.advance(3601)

          expect(runner(grace_period: 3600, force: true).call(dry_run: false).swept).to eq(2)
        end

        specify "does not sweep entries marked within the grace period while it marks others" do
          publish("Order$1", 5)
          client.set_stream_metadata("Order$1", max_count: 2)
          runner.call(dry_run: false)
          clock.advance(DAY)
          publish("Order$1", 1)

          report = runner.call(dry_run: false)

          expect(report.marked).to eq(1)
          expect(report.swept).to eq(0)
          expect(links("Order$1")).to eq(6)
        end

        specify "a dry run within the grace period reports nothing to sweep" do
          publish("Order$1", 5)
          client.set_stream_metadata("Order$1", max_count: 2)
          runner.call(dry_run: false)
          clock.advance(DAY)

          expect(runner.call.streams).to eq([])
        end

        specify "marks and sweeps in one run with no grace period" do
          publish("Order$1", 3)
          client.set_stream_metadata("Order$1", max_count: 1)
          real_clock = -> { Time.now.utc }

          report = runner(grace_period: 0, force: true, clock: real_clock).call(dry_run: false)

          expect(report.marked).to eq(2)
          expect(report.swept).to eq(2)
        end

        specify "keeps the events in the global stream" do
          event_ids = publish("Order$1", 3)
          client.set_stream_metadata("Order$1", max_count: 1)
          runner.call(dry_run: false)
          sweep_day
          runner.call(dry_run: false)

          expect(client.read.map(&:event_id)).to include(*event_ids)
        end

        specify "keeps the position anchor" do
          publish("Order$1", 3)
          client.soft_delete_stream("Order$1")
          sweep_day

          expect(runner.call(dry_run: false).swept).to eq(2)
          expect(links("Order$1")).to eq(1)

          client.publish(RubyEventStore::Event.new, stream_name: "Order$1", expected_version: 2)
          expect(read("Order$1").size).to eq(1)
        end

        specify "keeps the tombstone sentinel" do
          publish("Order$1", 3)
          client.tombstone_stream("Order$1")
          client.soft_delete_stream("Order$1")
          sweep_day

          expect(runner.call(dry_run: false).swept).to eq(3)
          expect { client.publish(RubyEventStore::Event.new, stream_name: "Order$1") }.to raise_error(StreamTombstoned)
        end

        specify "records StreamScavenged in the meta stream" do
          publish("Order$1", 3)
          client.set_stream_metadata("Order$1", max_count: 1)
          runner.call(dry_run: false)
          sweep_day

          runner.call(dry_run: false)

          scavenged = scavenged("Order$1")
          expect(scavenged.size).to eq(1)
          expect(scavenged.first.data).to eq(
            "stream" => "Order$1",
            "policy" => "links_only",
            "removed_links" => 2,
            "removed_events" => 0,
          )
          expect(scavenged.first.timestamp).to eq(clock.call.round(TIMESTAMP_PRECISION))
          expect(scavenged.first.timestamp).not_to eq(clock.call)
          expect(scavenged.first.valid_at).to eq(clock.call.round(TIMESTAMP_PRECISION))
          expect(scavenged.first.metadata.to_h).to eq(
            timestamp: scavenged.first.timestamp,
            valid_at: scavenged.first.valid_at,
          )
        end

        specify "records no StreamScavenged when nothing was swept" do
          publish("Order$1", 3)
          client.set_stream_metadata("Order$1", max_count: 1)

          runner.call(dry_run: false)

          expect(scavenged("Order$1")).to eq([])
        end

        specify "is idempotent" do
          publish("Order$1", 3)
          client.set_stream_metadata("Order$1", max_count: 1)
          runner.call(dry_run: false)
          sweep_day
          runner.call(dry_run: false)

          report = runner.call(dry_run: false)

          expect(report.streams).to eq([])
          expect(scavenged("Order$1").size).to eq(1)
        end

        specify "processes streams in batches" do
          event_ids = publish("Order$1", 5)
          client.set_stream_metadata("Order$1", max_count: 1)

          batches = subscribe("scavenge_batch.ruby_event_store") { runner(batch_size: 2).call(dry_run: false) }

          expect(batches.map(&:payload)).to eq(
            [
              { stream: Stream.new("Order$1"), phase: :mark, size: 2 },
              { stream: Stream.new("Order$1"), phase: :mark, size: 2 },
              { stream: Stream.new("Order$1"), phase: :mark, size: 0 },
              { stream: Stream.new("Order$1"), phase: :sweep, size: 0 },
            ],
          )
          expect(read("Order$1")).to eq(event_ids.last(1))
        end

        specify "goes through every page of streams" do
          names = %w[a b c d e]
          names.each do |name|
            publish(name, 2)
            client.set_stream_metadata(name, max_count: 1)
          end
          allow(strategy).to receive(:streams).and_call_original

          report = runner(batch_size: 2).call(dry_run: false)

          expect(strategy).to have_received(:streams).with(after: nil, limit: 2).ordered
          expect(strategy).to have_received(:streams).with(after: "b", limit: 2).ordered
          expect(strategy).to have_received(:streams).with(after: "d", limit: 2).ordered
          expect(strategy).to have_received(:streams).with(after: "e", limit: 2).ordered

          expect(report.streams.map { |result| result.stream.name }).to eq(names)
          expect(report.marked).to eq(5)
        end

        specify "throttles between batches" do
          publish("Order$1", 5)
          client.set_stream_metadata("Order$1", max_count: 1)

          runner(batch_size: 2, throttle: 0.5).call(dry_run: false)

          expect(slept).to eq([0.5, 0.5])
        end

        specify "sleeps with Kernel by default" do
          publish("Order$1", 5)
          client.set_stream_metadata("Order$1", max_count: 1)
          allow(Kernel).to receive(:sleep)

          Runner.new(
            repository: repository,
            strategy: strategy,
            state: state,
            clock: clock,
            allow_in_process: true,
            batch_size: 2,
            throttle: 0.5,
          ).call(dry_run: false)

          expect(Kernel).to have_received(:sleep).with(0.5).twice
        end

        specify "does not sleep without throttle" do
          publish("Order$1", 5)
          client.set_stream_metadata("Order$1", max_count: 1)

          runner(batch_size: 2).call(dry_run: false)

          expect(slept).to eq([])
        end

        specify "default batch size" do
          publish("Order$1", 3)
          client.set_stream_metadata("Order$1", max_count: 1)

          batches = subscribe("scavenge_batch.ruby_event_store") { runner.call(dry_run: false) }

          expect(batches.map { |batch| batch.payload.fetch(:size) }).to eq([2, 0])
        end

        specify "selects streams by name" do
          %w[a b c].each do |name|
            publish(name, 2)
            client.set_stream_metadata(name, max_count: 1)
          end

          expect(runner(streams: %w[a c]).call(dry_run: false).streams.map { |result| result.stream.name }).to eq(
            %w[a c],
          )
          expect(read("b").size).to eq(2)
        end

        specify "selects streams with a callable" do
          %w[a b c].each do |name|
            publish(name, 2)
            client.set_stream_metadata(name, max_count: 1)
          end

          report = runner(streams: ->(name) { name.eql?("b") }).call(dry_run: false)

          expect(report.streams.map { |result| result.stream.name }).to eq(%w[b])
        end

        specify "leaves streams without metadata alone" do
          publish("Order$1", 3)

          expect(runner.call(dry_run: false).streams).to eq([])
          expect(read("Order$1").size).to eq(3)
        end
      end

      describe "status and cursor" do
        specify "idle with no cursor after a finished run" do
          publish("a", 2)
          client.set_stream_metadata("a", max_count: 1)

          runner.call(dry_run: false)

          expect(state.status).to eq(
            Status.new(status: :idle, stream: nil, cursor: nil, updated_at: clock.call.floor(TIMESTAMP_PRECISION)),
          )
        end

        specify "marking and sweeping while a stream is processed" do
          publish("a", 2)
          publish("b", 2)
          client.set_stream_metadata("a", max_count: 1)
          client.set_stream_metadata("b", max_count: 1)
          state.save(status: :idle, stream: nil, cursor: "a")
          statuses = []
          callback = ->(*, payload) do
            status = state.status
            statuses << [payload.fetch(:phase), status.status, status.stream, status.cursor]
          end

          ActiveSupport::Notifications.subscribed(callback, "scavenge_batch.ruby_event_store") do
            runner.call(dry_run: false)
          end

          expect(statuses).to eq([[:mark, :marking, "b", "a"], [:sweep, :sweeping, "b", "a"]])
        end

        specify "records the cursor after each page of streams" do
          %w[a b c].each do |name|
            publish(name, 2)
            client.set_stream_metadata(name, max_count: 1)
          end
          allow(strategy).to receive(:plan).and_call_original
          allow(strategy).to receive(:plan).with(Stream.new("c"), any_args).and_raise("boom")

          expect { runner(batch_size: 2).call(dry_run: false) }.to raise_error("boom")

          expect(state.status).to eq(
            Status.new(status: :idle, stream: nil, cursor: "b", updated_at: clock.call.floor(TIMESTAMP_PRECISION)),
          )
        end

        specify "runs again after an interrupted run" do
          %w[a b].each do |name|
            publish(name, 2)
            client.set_stream_metadata(name, max_count: 1)
          end
          runner = runner()
          tick = ->(*) { clock.advance(300) }
          ActiveSupport::Notifications.subscribed(tick, "scavenge_stream.ruby_event_store") do
            runner.call(dry_run: false)
          end

          report = runner.call(dry_run: false)

          expect(report.outcome).to eq(:finished)
          expect(report.streams.map { |result| result.stream.name }).to eq(%w[b])
        end

        specify "stops after max_duration and resumes with the stream it stopped at" do
          %w[a b c].each do |name|
            publish(name, 5)
            client.set_stream_metadata(name, max_count: 1)
          end
          tick = ->(*, payload) { clock.advance(10) if payload.fetch(:stream).name.eql?("b") }

          report =
            ActiveSupport::Notifications.subscribed(tick, "scavenge_batch.ruby_event_store") do
              runner(batch_size: 2, max_duration: 15).call(dry_run: false)
            end

          expect(report.outcome).to eq(:interrupted)
          expect(report.streams).to eq(
            [
              Report::StreamResult.new(stream: Stream.new("a"), reasons: [:max_count], marked: 4, swept: 0),
              Report::StreamResult.new(stream: Stream.new("b"), reasons: [:max_count], marked: 4, swept: 0),
            ],
          )
          expect(state.status.status).to eq(:idle)
          expect(state.status.cursor).to eq("a")
          expect(read("c").size).to eq(5)

          resumed = runner(batch_size: 2).call(dry_run: false)

          expect(resumed.outcome).to eq(:finished)
          expect(resumed.streams.map { |result| result.stream.name }).to eq(%w[c])
          expect(state.status.cursor).to be_nil
        end

        specify "stops between streams after max_duration" do
          %w[a b].each do |name|
            publish(name, 2)
            client.set_stream_metadata(name, max_count: 1)
          end
          tick = ->(*, payload) { clock.advance(300) if payload.fetch(:stream).name.eql?("a") }

          report =
            ActiveSupport::Notifications.subscribed(tick, "scavenge_stream.ruby_event_store") do
              runner.call(dry_run: false)
            end

          expect(report.outcome).to eq(:interrupted)
          expect(report.streams.map { |result| result.stream.name }).to eq(%w[a])
          expect(state.status.cursor).to eq("a")
        end

        specify "does not sweep a stream when max_duration ran out while marking it" do
          publish("a", 5)
          client.set_stream_metadata("a", max_count: 1)
          tick = ->(*) { clock.advance(300) }

          phases =
            subscribe("scavenge_batch.ruby_event_store") do
              ActiveSupport::Notifications.subscribed(tick, "scavenge_batch.ruby_event_store") do
                runner(batch_size: 2, grace_period: 0, force: true).call(dry_run: false)
              end
            end

          expect(phases.map { |batch| batch.payload.fetch(:phase) }).to eq([:mark])
          expect(state.status.cursor).to be_nil
        end

        specify "records StreamScavenged when max_duration ran out while sweeping" do
          publish("a", 5)
          client.set_stream_metadata("a", max_count: 1)
          runner.call(dry_run: false)
          sweep_day
          tick = ->(*, payload) { clock.advance(300) if payload.fetch(:phase).equal?(:sweep) }

          report =
            ActiveSupport::Notifications.subscribed(tick, "scavenge_batch.ruby_event_store") do
              runner(batch_size: 2).call(dry_run: false)
            end

          expect(report.outcome).to eq(:interrupted)
          expect(report.swept).to eq(2)
          expect(scavenged("a").map { |event| event.data.fetch("removed_links") }).to eq([2])
        end

        specify "a dry run stops after max_duration" do
          %w[a b].each do |name|
            publish(name, 2)
            client.set_stream_metadata(name, max_count: 1)
          end
          tick = ->(*) { clock.advance(300) }

          report = ActiveSupport::Notifications.subscribed(tick, "scavenge_stream.ruby_event_store") { runner.call }

          expect(report.outcome).to eq(:interrupted)
          expect(report.streams.map { |result| result.stream.name }).to eq(%w[a])
        end

        specify "default max_duration" do
          %w[a b].each do |name|
            publish(name, 2)
            client.set_stream_metadata(name, max_count: 1)
          end
          tick = ->(*) { clock.advance(299) }

          report = ActiveSupport::Notifications.subscribed(tick, "scavenge_stream.ruby_event_store") { runner.call }

          expect(report.outcome).to eq(:finished)

          tick = ->(*) { clock.advance(300) }
          report = ActiveSupport::Notifications.subscribed(tick, "scavenge_stream.ruby_event_store") { runner.call }
          expect(report.outcome).to eq(:interrupted)
        end

        specify "starts after the cursor" do
          %w[a b].each do |name|
            publish(name, 2)
            client.set_stream_metadata(name, max_count: 1)
          end
          state.save(status: :idle, stream: nil, cursor: "a")

          expect(runner.call(dry_run: false).streams.map { |result| result.stream.name }).to eq(%w[b])
          expect(read("a").size).to eq(2)
        end
      end

      describe "lock" do
        specify "does nothing when another run holds the lock" do
          publish("a", 2)
          client.set_stream_metadata("a", max_count: 1)
          lock = instance_double(Lock, synchronize: false)

          report = runner(lock: lock).call(dry_run: false)

          expect(report).to eq(Report.new(policy: Policy.links_only, dry_run: false, outcome: :locked, streams: []))
          expect(read("a").size).to eq(2)
          expect(state.status).to eq(Status.initial)
        end

        specify "runs holding the lock" do
          publish("a", 2)
          client.set_stream_metadata("a", max_count: 1)
          held = []
          lock = Lock.new(state: state)
          allow(lock).to receive(:synchronize).and_wrap_original do |original, &block|
            original.call do
              held << true
              block.call
            end
          end

          expect(runner(lock: lock).call(dry_run: false).marked).to eq(1)
          expect(held).to eq([true])
        end

        specify "uses a lock on the state by default" do
          publish("a", 2)
          client.set_stream_metadata("a", max_count: 1)
          state.claim("someone else", stale_before: clock.call - 3600) if SpecHelper.new.sqlite?

          if SpecHelper.new.sqlite?
            expect(runner.call(dry_run: false).outcome).to eq(:locked)
          else
            expect(runner.call(dry_run: false).outcome).to eq(:finished)
          end
        end
      end

      describe "instrumentation" do
        specify "instruments the run" do
          publish("a", 2)
          client.set_stream_metadata("a", max_count: 1)
          report = nil

          events = subscribe("scavenge.ruby_event_store") { report = runner.call(dry_run: false) }

          expect(events.map(&:payload)).to eq([{ policy: Policy.links_only, dry_run: false, report: report }])
        end

        specify "instruments a dry run" do
          report = nil

          events = subscribe("scavenge.ruby_event_store") { report = runner.call }

          expect(events.map(&:payload)).to eq([{ policy: Policy.links_only, dry_run: true, report: report }])
        end

        specify "instruments each stream" do
          publish("a", 3)
          client.set_stream_metadata("a", max_count: 1)
          runner.call(dry_run: false)
          sweep_day

          events = subscribe("scavenge_stream.ruby_event_store") { runner.call(dry_run: false) }

          expect(events.map(&:payload)).to eq(
            [{ stream: Stream.new("a"), reasons: [], dry_run: false, marked: 0, swept: 2 }],
          )
        end

        specify "instruments each stream of a dry run" do
          publish("a", 3)
          client.set_stream_metadata("a", max_count: 1)

          events = subscribe("scavenge_stream.ruby_event_store") { runner.call }

          expect(events.map(&:payload)).to eq(
            [{ stream: Stream.new("a"), reasons: [:max_count], dry_run: true, marked: 2, swept: 0 }],
          )
        end

        specify "uses the given instrumentation" do
          instrumentation = ActiveSupport::Notifications.instrumenter.class.new(ActiveSupport::Notifications.notifier)
          allow(instrumentation).to receive(:instrument).and_call_original

          runner(instrumentation: instrumentation).call

          expect(instrumentation).to have_received(:instrument).with("scavenge.ruby_event_store", anything)
        end
      end

      describe ".active_record" do
        specify "builds the repository and strategy with the serializer and model factory" do
          model_factory = ActiveRecord::WithDefaultModels.new
          allow(ActiveRecord::EventRepository).to receive(:new).and_call_original
          allow(ActiveRecord::ScavengeStrategy).to receive(:new).and_call_original

          Runner.active_record(serializer: ::JSON, model_factory: model_factory, allow_in_process: true)

          expect(ActiveRecord::EventRepository).to have_received(:new).with(
            serializer: ::JSON,
            model_factory: model_factory,
          )
          expect(ActiveRecord::ScavengeStrategy).to have_received(:new).with(model_factory: model_factory)
        end

        specify "records StreamScavenged with the serializer given" do
          publish("a", 3)
          client.set_stream_metadata("a", max_count: 1)
          runner.call(dry_run: false)
          sweep_day

          Runner.active_record(
            serializer: SpecHelper.serializer,
            allow_in_process: true,
            state: state,
            clock: clock,
          ).call(dry_run: false)

          expect(scavenged("a").map { |event| event.data.fetch("removed_links") }).to eq([2])
        end

        specify "runs on the tables of the ActiveRecord repository" do
          event_ids = publish("a", 3)
          client.set_stream_metadata("a", max_count: 1)

          report =
            Runner.active_record(serializer: SpecHelper.serializer, allow_in_process: true, state: state).call(
              dry_run: false,
            )

          expect(report.marked).to eq(2)
          expect(read("a")).to eq(event_ids.last(1))
        end

        specify "with a model factory" do
          model_factory = ActiveRecord::WithAbstractBaseClass.new(CustomApplicationRecord)
          publish("a", 3)
          client.set_stream_metadata("a", max_count: 1)
          state = State.new(base: CustomApplicationRecord)

          report =
            Runner.active_record(
              serializer: SpecHelper.serializer,
              model_factory: model_factory,
              base: CustomApplicationRecord,
              allow_in_process: true,
            ).call(dry_run: false)

          expect(report.marked).to eq(2)
          expect(state.status.status).to eq(:idle)
        end
      end
    end
  end
end
