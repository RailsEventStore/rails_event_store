# frozen_string_literal: true

require "json"
require "optparse"

module RubyEventStore
  module Scavenger
    # res-scavenge [run] [options]   - a dry run unless --execute
    # res-scavenge status [options]  - the status recorded by the last run
    class CLI
      SERIALIZERS = { "yaml" => Serializers::YAML, "json" => ::JSON }.freeze
      ENV_OPTIONS = {
        "GRACE_PERIOD" => "--grace-period",
        "BATCH_SIZE" => "--batch-size",
        "MAX_DURATION" => "--max-duration",
        "THROTTLE" => "--throttle",
        "POLICY" => "--policy",
        "SERIALIZER" => "--serializer",
      }.freeze
      ENV_FLAGS = {
        "EXECUTE" => "--execute",
        "FORCE" => "--force",
        "I_UNDERSTAND_GLOBAL_POSITION_GAPS" => "--i-understand-global-position-gaps",
      }.freeze
      COMMANDS = { [] => :scavenge, %w[run] => :scavenge, %w[status] => :status }.freeze

      # Command line of the rake task: EXECUTE=1, FORCE=1, I_UNDERSTAND_GLOBAL_POSITION_GAPS=1,
      # GRACE_PERIOD, BATCH_SIZE, MAX_DURATION, THROTTLE, POLICY, SERIALIZER and STREAMS (names
      # separated by commas).
      def self.argv_from_env(env)
        flags = ENV_FLAGS.filter_map { |name, flag| flag if %w[1 true].include?(env[name]) }
        options = ENV_OPTIONS.flat_map { |name, option| env.key?(name) ? [option, env.fetch(name)] : [] }
        streams = env.fetch("STREAMS", "").split(",").flat_map { |name| ["--stream", name] }
        flags + options + streams
      end

      def initialize(out: $stdout, err: $stderr)
        @out = out
        @err = err
      end

      # @param connect [Boolean] whether to connect to --database-url (DATABASE_URL by default);
      #   false uses the connection of an application already loaded, as the rake task does
      # @return [Integer] exit code
      def run(argv, connect: false, env: ENV)
        command, options = parse(argv)
        return 0 if command.nil?
        if connect
          url = options.fetch(:database_url) { env.fetch("DATABASE_URL", nil) }
          raise OptionParser::MissingArgument, "--database-url (or DATABASE_URL)" if url.nil?
          ::ActiveRecord::Base.establish_connection(url)
        end
        case command
        when :status
          status
        when :scavenge
          scavenge(options)
        end
        0
      rescue OptionParser::ParseError, Error => e
        @err.puts(e)
        1
      end

      private

      def parse(argv)
        options = { serializer: Serializers::YAML, runner: {}, execute: false }
        runner = options.fetch(:runner)
        parser =
          OptionParser.new do |o|
            o.banner = "Usage: res-scavenge [run|status] [options]"
            o.on("--database-url URL", "Database to connect to (default: DATABASE_URL)") do |url|
              options[:database_url] = url
            end
            o.on("--execute", "Mark and sweep; without it only report what a run would do") { options[:execute] = true }
            o.on("--force", "Allow a grace period shorter than 7 days") { runner[:force] = true }
            o.on("--grace-period SECONDS", Integer, "Sweep entries hidden longer ago (default: 7 days)") do |seconds|
              runner[:grace_period] = seconds
            end
            o.on("--batch-size N", Integer, "Entries per batch (default: 1000)") { |size| runner[:batch_size] = size }
            o.on("--max-duration SECONDS", Integer, "Stop cleanly after (default: 300)") do |seconds|
              runner[:max_duration] = seconds
            end
            o.on("--throttle SECONDS", Float, "Sleep between batches (default: 0)") do |seconds|
              runner[:throttle] = seconds
            end
            o.on("--policy NAME", "links_only (default) or purge, which also removes events") do |name|
              runner[:policy] = name
            end
            o.on(
              "--i-understand-global-position-gaps",
              "Confirm policy purge: removed events leave gaps in global positions",
            ) { runner[:confirm] = Runner::PURGE_CONFIRMATION }
            o.on("--stream NAME", "Only this stream; may be repeated") do |name|
              (runner[:streams] = Array(runner[:streams])) << name
            end
            o.on(
              "--serializer NAME",
              SERIALIZERS,
              "Serializer of the event store: yaml (default), json",
            ) { |serializer| options[:serializer] = serializer }
            o.on("-h", "--help", "Show this help") do
              @out.puts(o)
              return
            end
          end
        arguments = parser.parse(argv)
        [COMMANDS.fetch(arguments) { raise OptionParser::InvalidArgument, arguments }, options]
      end

      def status
        @out.puts(State.new.status)
      end

      def scavenge(options)
        runner =
          Runner.active_record(serializer: options.fetch(:serializer), allow_in_process: true, **options.fetch(:runner))
        @out.write(render(runner.call(dry_run: !options.fetch(:execute))), "\n")
      end

      def render(report)
        return "Another scavenger run holds the lock; nothing done." if report.outcome.equal?(:locked)
        header = report.dry_run ? "Dry run, nothing changed." : "Scavenged."
        lines = ["#{header} Policy: #{report.policy}. Outcome: #{report.outcome}."]
        report.streams.each do |result|
          reasons = " (#{result.reasons.join(", ")})" unless result.reasons.empty?
          lines << "#{result.stream.name}: #{counts(report, result)}#{reasons}"
        end
        lines << "Total: #{counts(report, report)}."
        lines.join("\n")
      end

      # Counts of a stream result or of the whole report; what was purged only with policy purge.
      def counts(report, result)
        mark, sweep, purge = report.dry_run ? ["to mark", "to sweep", "to purge"] : %w[marked swept purged]
        purged = ", #{purge} #{result.purged}" if report.policy.purge?
        "#{mark} #{result.marked}, #{sweep} #{result.swept}#{purged}"
      end
    end
  end
end
