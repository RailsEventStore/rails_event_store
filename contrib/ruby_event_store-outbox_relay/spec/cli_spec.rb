# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/outbox_relay/cli"
require "tmpdir"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe CLI do
      describe CLI::Parser do
        specify "defaults to a batch of 100, one second polling and the info log level" do
          options = CLI::Parser.parse(["--require=config/outbox_relay.rb"])

          expect(options.to_h).to eq(batch_size: 100, poll_interval: 1.0, log_level: :info, require_path: "config/outbox_relay.rb")
        end

        specify "parses every option" do
          options =
            CLI::Parser.parse(
              %w[--require=relay.rb --batch-size=25 --poll-interval=0.5 --log-level=debug],
            )

          expect(options.to_h).to eq(batch_size: 25, poll_interval: 0.5, log_level: :debug, require_path: "relay.rb")
        end

        specify "has no way to pass the database URL, which would leak it into the process list" do
          expect { CLI::Parser.parse(%w[--require=relay.rb --database-url=postgres://user:secret@host/db]) }.to raise_error(
            OptionParser::InvalidOption,
          )
          expect(CLI::Options.members).not_to include(:database_url)
        end

        specify "points to DATABASE_URL in its help" do
          help = StringIO.new
          allow(OptionParser).to receive(:new).and_wrap_original do |original, *args, &block|
            original.call(*args) { |o| block.call(o).tap { help << o.help } }
          end

          CLI::Parser.parse(["--require=relay.rb"])

          expect(help.string).to include("DATABASE_URL environment variable, never from an argument")
        end

        specify "prints the version and exits" do
          expect { CLI::Parser.parse(["--version"]) }.to output("#{VERSION}\n").to_stdout.and raise_error(SystemExit)
        end
      end

      describe "#run" do
        around do |example|
          database_url = ENV["DATABASE_URL"]
          example.run
        ensure
          ENV["DATABASE_URL"] = database_url
        end

        def relay_file(dir)
          File.join(dir, "relay.rb").tap { |path| File.write(path, "$relay_file_loaded = true\n") }
        end

        specify "requires --require" do
          expect { CLI.new.run([]) }.to raise_error(ArgumentError, "--require is mandatory, see --help")
        end

        specify "connects to DATABASE_URL, loads the file and runs the configured relay with the given settings" do
          ENV["DATABASE_URL"] = "postgres://user:secret@host/db"
          relay = double(:relay, run: nil)
          allow(::ActiveRecord::Base).to receive(:establish_connection)
          allow(Configuration).to receive(:build).and_return(relay)

          Dir.mktmpdir do |dir|
            CLI.new.run(["--require=#{relay_file(dir)}", "--batch-size=7", "--poll-interval=0.25", "--log-level=warn"])
          end

          expect(::ActiveRecord::Base).to have_received(:establish_connection).with("postgres://user:secret@host/db")
          expect($relay_file_loaded).to eq(true)
          expect(Configuration).to have_received(:build).with(
            batch_size: 7,
            poll_interval: 0.25,
            logger: an_instance_of(Logger).and(having_attributes(level: Logger::WARN, progname: "RES-OutboxRelay")),
          )
          expect(relay).to have_received(:run)
        end

        specify "leaves the connection alone when DATABASE_URL isn't set" do
          ENV.delete("DATABASE_URL")
          allow(::ActiveRecord::Base).to receive(:establish_connection)
          allow(Configuration).to receive(:build).and_return(double(:relay, run: nil))

          Dir.mktmpdir { |dir| CLI.new.run(["--require=#{relay_file(dir)}"]) }

          expect(::ActiveRecord::Base).not_to have_received(:establish_connection)
        end
      end
    end
  end
end
