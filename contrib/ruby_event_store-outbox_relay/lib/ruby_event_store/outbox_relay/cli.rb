# frozen_string_literal: true

require "optparse"
require "logger"
require_relative "version"
require_relative "configuration"

module RubyEventStore
  module OutboxRelay
    class CLI
      DEFAULTS = {
        batch_size: nil,
        poll_interval: nil,
        lease_duration: nil,
        stats_interval: nil,
        stats: true,
        log_level: :info,
        require_path: nil,
      }.freeze
      Options = Struct.new(*DEFAULTS.keys)

      class Parser
        def self.parse(argv)
          options = Options.new(*DEFAULTS.values)
          OptionParser
            .new do |o|
              o.banner = "Usage: res_outbox_relay --require=config/outbox_relay.rb [options]"
              o.separator "The database is taken from the DATABASE_URL environment variable, never from an argument, " \
                            "so its credentials stay out of the process list."

              o.on(
                "--require=PATH",
                "Ruby file that calls RubyEventStore::OutboxRelay::Configuration.configure " \
                  "to build the relay (typically Relay.new(client: ...)). Mandatory.",
              ) { |v| options.require_path = v }

              o.on("--batch-size=BATCH_SIZE", Integer, "Amount of messages claimed in one batch. Default: 100") do |v|
                options.batch_size = v
              end

              o.on(
                "--poll-interval=SECONDS",
                Float,
                "How long to sleep before next check when there was nothing to do. Default: 1.0",
              ) { |v| options.poll_interval = v }

              o.on(
                "--lease-duration=SECONDS",
                Float,
                "How long a claimed message stays hidden from other relays; must exceed the time to deliver " \
                  "a batch. Default: 300",
              ) { |v| options.lease_duration = v }

              o.on(
                "--stats-interval=SECONDS",
                Float,
                "How often the stats notification is published. Default: 30",
              ) { |v| options.stats_interval = v }

              o.on("--no-stats", "Don't publish the stats notification") { options.stats = false }

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
        ::ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"]) if ENV["DATABASE_URL"]
        require File.expand_path(options.require_path)

        Configuration.build(**overrides(options)).run
      end

      private

      def overrides(options)
        given = options.to_h.slice(:batch_size, :poll_interval, :lease_duration, :stats_interval).compact
        given[:stats_interval] = nil unless options.stats
        given.merge(logger: Logger.new($stdout, level: options.log_level, progname: "RES-OutboxRelay"))
      end
    end
  end
end
