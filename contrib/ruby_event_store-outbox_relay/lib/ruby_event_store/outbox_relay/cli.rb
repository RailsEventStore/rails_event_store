# frozen_string_literal: true

require "optparse"
require "logger"
require_relative "version"
require_relative "configuration"

module RubyEventStore
  module OutboxRelay
    class CLI
      DEFAULTS = { database_url: nil, batch_size: 100, poll_interval: 1.0, log_level: :info, require_path: nil }.freeze
      Options = Struct.new(*DEFAULTS.keys)

      class Parser
        def self.parse(argv)
          options = Options.new(*DEFAULTS.values)
          OptionParser
            .new do |o|
              o.banner = "Usage: res_outbox_relay --require=config/outbox_relay.rb [options]"

              o.on("--database-url=DATABASE_URL", "Database where event_store_events is stored") do |v|
                options.database_url = v
              end

              o.on(
                "--require=PATH",
                "Ruby file that calls RubyEventStore::OutboxRelay::Configuration.configure " \
                  "to build the relay (typically Relay.new(client: ...)). Mandatory.",
              ) { |v| options.require_path = v }

              o.on("--batch-size=BATCH_SIZE", Integer, "Amount of events fetched in one batch. Default: 100") do |v|
                options.batch_size = v
              end

              o.on(
                "--poll-interval=SECONDS",
                Float,
                "How long to sleep before next check when there was nothing to do. Default: 1.0",
              ) { |v| options.poll_interval = v }

              o.on(
                "--log-level=LOG_LEVEL",
                %i[fatal error warn info debug],
                "Logging level, one of: fatal, error, warn, info, debug. Default: info",
              ) { |v| options.log_level = v.to_sym }

              o.on_tail("--version", "Show version") do
                puts VERSION
                exit
              end
            end
            .parse(argv)
          options
        end
      end

      def run(argv)
        options = Parser.parse(argv)
        raise ArgumentError, "--require is mandatory, see --help" unless options.require_path

        require "active_record"
        ::ActiveRecord::Base.establish_connection(options.database_url) if options.database_url
        require File.expand_path(options.require_path)

        logger = Logger.new($stdout, level: options.log_level, progname: "RES-OutboxRelay")
        relay = Configuration.build(batch_size: options.batch_size, poll_interval: options.poll_interval, logger: logger)
        relay.run
      end
    end
  end
end
