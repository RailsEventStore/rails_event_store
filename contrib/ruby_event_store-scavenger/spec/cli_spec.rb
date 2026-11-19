# frozen_string_literal: true

require "spec_helper"
require "stringio"

module RubyEventStore
  module Scavenger
    ::RSpec.describe CLI do
      let(:out) { StringIO.new }
      let(:err) { StringIO.new }
      let(:cli) { CLI.new(out: out, err: err) }
      let(:repository) { ActiveRecord::EventRepository.new(serializer: SpecHelper.serializer) }
      let(:client) { Client.new(repository: StreamMetadataAwareRepository.new(repository)) }

      def publish(stream_name, count)
        client.publish(
          Array.new(count) { RubyEventStore::Event.new },
          stream_name: stream_name,
          expected_version: :auto,
        )
      end

      # Sweeping writes StreamScavenged, which has to fit the data column.
      def serializer
        ["--serializer", SpecHelper.serializer_name]
      end

      def visible(stream_name)
        client.read.stream(stream_name).count
      end

      def links(stream_name)
        ::ActiveRecord::Base.connection.select_value(
          "SELECT COUNT(*) FROM event_store_events_in_streams WHERE stream = '#{stream_name}'",
        )
      end

      def backdate_marks
        ::ActiveRecord::Base.connection.execute(
          "UPDATE event_store_events_in_streams SET truncated_at = '2000-01-01 00:00:00' WHERE truncated_at IS NOT NULL",
        )
      end

      before do
        publish("Order$1", 5)
        client.set_stream_metadata("Order$1", max_count: 2)
      end

      specify "a dry run by default" do
        expect(cli.run([])).to eq(0)

        expect(out.string).to eq(<<~EOS)
          Dry run, nothing changed. Policy: links_only. Outcome: finished.
          Order$1: to mark 3, to sweep 0 (max_count)
          Total: to mark 3, to sweep 0.
        EOS
        expect(visible("Order$1")).to eq(5)
      end

      specify "a stream with several reasons" do
        client.set_stream_metadata("Order$1", max_count: 2, max_age: 1)
        client.truncate_stream("Order$1", before: 1)

        cli.run([])

        expect(out.string).to include("Order$1: to mark 2, to sweep 0 (truncate_before, max_count)\n")
      end

      specify "help of the executable needs no database" do
        allow(::ActiveRecord::Base).to receive(:establish_connection)

        expect(cli.run(["--help"], connect: true, env: {})).to eq(0)

        expect(err.string).to eq("")
        expect(::ActiveRecord::Base).not_to have_received(:establish_connection)
      end

      specify "short help" do
        status = nil
        expect { status = cli.run(["-h"]) }.not_to raise_error
        expect(status).to eq(0)
        expect(out.string).to start_with("Usage: res-scavenge")
      end

      specify "run is the default command" do
        expect(cli.run(["run"])).to eq(0)
        expect(out.string).to start_with("Dry run, nothing changed.")
      end

      specify "executes with --execute" do
        expect(cli.run(["--execute"])).to eq(0)

        expect(out.string).to eq(<<~EOS)
          Scavenged. Policy: links_only. Outcome: finished.
          Order$1: marked 3, swept 0 (max_count)
          Total: marked 3, swept 0.
        EOS
        expect(visible("Order$1")).to eq(2)
      end

      specify "a stream with nothing but entries to sweep" do
        cli.run(["--execute"])
        backdate_marks
        out.truncate(0)
        out.rewind

        cli.run(["--execute", *serializer])

        expect(out.string).to eq(<<~EOS)
          Scavenged. Policy: links_only. Outcome: finished.
          Order$1: marked 0, swept 3
          Total: marked 0, swept 3.
        EOS
      end

      specify "sweeps after the default grace period only" do
        cli.run(["--execute"])
        ::ActiveRecord::Base.connection.execute(
          "UPDATE event_store_events_in_streams SET truncated_at = '#{(Time.now.utc - 7 * 24 * 3600 + 60).strftime("%Y-%m-%d %H:%M:%S")}' WHERE truncated_at IS NOT NULL",
        )

        cli.run(["--execute"])

        expect(links("Order$1")).to eq(5)
      end

      specify "grace period needs --force when shorter than 7 days" do
        expect(cli.run(%w[--execute --grace-period 0])).to eq(1)
        expect(err.string).to eq("A grace period shorter than 604800 seconds needs force\n")

        expect(cli.run([*%w[--execute --grace-period 0 --force], *serializer])).to eq(0)
        expect(links("Order$1")).to eq(2)
      end

      specify "batch size, max duration and throttle" do
        runner =
          instance_double(
            Runner,
            call: Report.new(policy: Policy.links_only, dry_run: true, outcome: :finished, streams: []),
          )
        allow(Runner).to receive(:active_record).and_return(runner)

        cli.run(%w[--batch-size 7 --max-duration 9 --throttle 0.25 --policy links_only --stream a --stream b])

        expect(Runner).to have_received(:active_record).with(
          serializer: Serializers::YAML,
          allow_in_process: true,
          batch_size: 7,
          max_duration: 9,
          throttle: 0.25,
          policy: "links_only",
          streams: %w[a b],
        )
        expect(runner).to have_received(:call).with(dry_run: true)
      end

      specify "serializer" do
        runner =
          instance_double(
            Runner,
            call: Report.new(policy: Policy.links_only, dry_run: false, outcome: :finished, streams: []),
          )
        allow(Runner).to receive(:active_record).and_return(runner)

        cli.run(%w[--serializer json --execute])

        expect(Runner).to have_received(:active_record).with(serializer: ::JSON, allow_in_process: true)
        expect(runner).to have_received(:call).with(dry_run: false)
      end

      specify "only the given streams" do
        publish("Order$2", 3)
        client.set_stream_metadata("Order$2", max_count: 1)

        cli.run(%w[--execute --stream Order$2])

        expect(visible("Order$1")).to eq(5)
        expect(visible("Order$2")).to eq(1)
      end

      specify "an interrupted run" do
        runner =
          instance_double(
            Runner,
            call: Report.new(policy: Policy.links_only, dry_run: false, outcome: :interrupted, streams: []),
          )
        allow(Runner).to receive(:active_record).and_return(runner)

        cli.run(["--execute"])

        expect(out.string).to eq("Scavenged. Policy: links_only. Outcome: interrupted.\nTotal: marked 0, swept 0.\n")
      end

      specify "another run holds the lock" do
        runner =
          instance_double(
            Runner,
            call: Report.new(policy: Policy.links_only, dry_run: false, outcome: :locked, streams: []),
          )
        allow(Runner).to receive(:active_record).and_return(runner)

        expect(cli.run(["--execute"])).to eq(0)
        expect(out.string).to eq("Another scavenger run holds the lock; nothing done.\n")
      end

      specify "status" do
        State.new.save(status: :idle, stream: nil, cursor: "Order$1")

        expect(cli.run(["status"])).to eq(0)

        expect(out.string).to match(
          /\Astatus: idle\nstream: -\ncursor: Order\$1\nupdated_at: \d{4}-\d\d-\d\dT[\d:.]+Z\n\z/,
        )
      end

      specify "help" do
        status = nil
        expect { status = cli.run(["--help"]) }.not_to raise_error
        expect(status).to eq(0)

        expect(out.string).to eq(<<~EOS)
          Usage: res-scavenge [run|status] [options]
                  --database-url URL           Database to connect to (default: DATABASE_URL)
                  --execute                    Mark and sweep; without it only report what a run would do
                  --force                      Allow a grace period shorter than 7 days
                  --grace-period SECONDS       Sweep entries hidden longer ago (default: 7 days)
                  --batch-size N               Entries per batch (default: 1000)
                  --max-duration SECONDS       Stop cleanly after (default: 300)
                  --throttle SECONDS           Sleep between batches (default: 0)
                  --policy NAME                links_only (default)
                  --stream NAME                Only this stream; may be repeated
                  --serializer NAME            Serializer of the event store: yaml (default), json
              -h, --help                       Show this help
        EOS
        expect(err.string).to eq("")
        expect(visible("Order$1")).to eq(5)
      end

      specify "unknown command" do
        expect(cli.run(["sweep"])).to eq(1)
        expect(err.string).to eq("invalid argument: sweep\n")
      end

      specify "too many arguments" do
        expect(cli.run(%w[run status])).to eq(1)
        expect(err.string).to eq("invalid argument: run status\n")
      end

      specify "invalid option" do
        expect(cli.run(["--nope"])).to eq(1)
        expect(err.string).to eq("invalid option: --nope\n")
      end

      specify "invalid number" do
        expect(cli.run(%w[--batch-size many])).to eq(1)
        expect(err.string).to eq("invalid argument: --batch-size many\n")
      end

      specify "unknown policy" do
        expect(cli.run(%w[--policy purge])).to eq(1)
        expect(err.string).to eq("Unknown scavenger policy: \"purge\"\n")
      end

      specify "connects to --database-url" do
        allow(::ActiveRecord::Base).to receive(:establish_connection)

        cli.run(%w[status --database-url sqlite3::memory:], connect: true, env: {})

        expect(::ActiveRecord::Base).to have_received(:establish_connection).with("sqlite3::memory:")
      end

      specify "connects to DATABASE_URL by default" do
        allow(::ActiveRecord::Base).to receive(:establish_connection)

        cli.run(%w[status], connect: true, env: { "DATABASE_URL" => "sqlite3::memory:" })

        expect(::ActiveRecord::Base).to have_received(:establish_connection).with("sqlite3::memory:")
      end

      specify "--database-url wins over DATABASE_URL" do
        allow(::ActiveRecord::Base).to receive(:establish_connection)

        cli.run(%w[status --database-url sqlite3::memory:], connect: true, env: { "DATABASE_URL" => "other" })

        expect(::ActiveRecord::Base).to have_received(:establish_connection).with("sqlite3::memory:")
      end

      specify "needs a database to connect to" do
        allow(::ActiveRecord::Base).to receive(:establish_connection)

        expect(cli.run(%w[status], connect: true, env: {})).to eq(1)

        expect(err.string).to eq("missing argument: --database-url (or DATABASE_URL)\n")
        expect(::ActiveRecord::Base).not_to have_received(:establish_connection)
      end

      specify "does not connect by default" do
        allow(::ActiveRecord::Base).to receive(:establish_connection)

        cli.run(%w[status --database-url sqlite3::memory:])

        expect(::ActiveRecord::Base).not_to have_received(:establish_connection)
      end

      specify "reads ENV by default" do
        allow(::ActiveRecord::Base).to receive(:establish_connection)
        previous = ENV["DATABASE_URL"]

        cli.run(%w[status], connect: true)

        expect(::ActiveRecord::Base).to have_received(:establish_connection).with(previous)
      end

      specify "default output" do
        expect { CLI.new.run(["status"]) }.to output(/\Astatus: idle/).to_stdout
        expect { CLI.new.run(["nope"]) }.to output("invalid argument: nope\n").to_stderr
      end
    end

    ::RSpec.describe CLI, ".argv_from_env", db: false do
      specify "nothing" do
        expect(CLI.argv_from_env({})).to eq([])
      end

      specify "every option" do
        env = {
          "EXECUTE" => "1",
          "FORCE" => "true",
          "GRACE_PERIOD" => "60",
          "BATCH_SIZE" => "10",
          "MAX_DURATION" => "30",
          "THROTTLE" => "0.1",
          "POLICY" => "links_only",
          "SERIALIZER" => "json",
          "STREAMS" => "a,b",
        }

        expect(CLI.argv_from_env(env)).to eq(
          %w[
            --execute
            --force
            --grace-period
            60
            --batch-size
            10
            --max-duration
            30
            --throttle
            0.1
            --policy
            links_only
            --serializer
            json
            --stream
            a
            --stream
            b
          ],
        )
      end

      specify "flags only when 1 or true" do
        expect(CLI.argv_from_env("EXECUTE" => "0", "FORCE" => "yes")).to eq([])
        expect(CLI.argv_from_env("EXECUTE" => "true", "FORCE" => "1")).to eq(%w[--execute --force])
      end
    end
  end
end
