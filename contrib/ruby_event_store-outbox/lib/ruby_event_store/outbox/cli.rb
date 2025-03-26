# frozen_string_literal: true

require "optparse"
require_relative "version"
require_relative "consumer"
require_relative "runner"
require_relative "metrics"
require_relative "configuration"

module RubyEventStore
  module Outbox
    class CLI
      DEFAULTS = {
        database_url: nil,
        redis_url: nil,
        log_level: :warn,
        split_keys: nil,
        message_format: "sidekiq5",
        batch_size: 100,
        metrics_url: nil,
        cleanup_strategy: :none,
        cleanup_limit: :all,
        sleep_on_empty: 0.5,
        locking: true,
      }
      Options = Struct.new(*DEFAULTS.keys)

      class Parser
        def self.parse(argv)
          options = Options.new(*DEFAULTS.values)
          OptionParser
            .new do |option_parser|
              option_parser.banner = "Usage: res_outbox [options]"

              option_parser.on(
                "--database-url=DATABASE_URL",
                "Database where outbox table is stored"
              ) { |database_url| options.database_url = database_url }

              option_parser.on("--redis-url=REDIS_URL", "URL to redis database") do |redis_url|
                options.redis_url = redis_url
              end

              option_parser.on(
                "--log-level=LOG_LEVEL",
                %i[fatal error warn info debug],
                "Logging level, one of: fatal, error, warn, info, debug. Default: warn"
              ) { |log_level| options.log_level = log_level.to_sym }

              option_parser.on(
                "--message-format=FORMAT",
                ["sidekiq5"],
                "Message format, supported: sidekiq5. Default: sidekiq5"
              ) { |message_format| options.message_format = message_format }

              option_parser.on(
                "--split-keys=SPLIT_KEYS",
                Array,
                "Split keys which should be handled, all if not specified"
              ) { |split_keys| options.split_keys = split_keys if !split_keys.empty? }

              option_parser.on(
                "--batch-size=BATCH_SIZE",
                Integer,
                "Amount of records fetched in one fetch. Bigger value means more duplicated messages when network problems occur. Default: 100"
              ) { |batch_size| options.batch_size = batch_size }

              option_parser.on("--metrics-url=METRICS_URL", "URI to metrics collector, optional") do |metrics_url|
                options.metrics_url = metrics_url
              end

              option_parser.on(
                "--cleanup=STRATEGY",
                "A strategy for cleaning old records. One of: none or iso8601 duration format how old enqueued records should be removed. Default: none"
              ) { |cleanup_strategy| options.cleanup_strategy = cleanup_strategy }

              option_parser.on(
                "--cleanup-limit=LIMIT",
                "Amount of records removed in single cleanup run. One of: all or number of records that should be removed. Default: all"
              ) { |cleanup_limit| options.cleanup_limit = cleanup_limit }

              option_parser.on(
                "--sleep-on-empty=SLEEP_TIME",
                Float,
                "How long to sleep before next check when there was nothing to do. Default: 0.5"
              ) { |sleep_on_empty| options.sleep_on_empty = sleep_on_empty }

              option_parser.on("-l", "--[no-]lock", "Lock split key in consumer") do |locking|
                options.locking = locking
              end

              option_parser.on_tail("--version", "Show version") do
                puts VERSION
                exit
              end
            end
            .parse(argv)
          return options
        end
      end

      def run(argv)
        options = Parser.parse(argv)
        build_runner(options)
          .run
      end

      def build_runner(options)
        consumer_uuid = SecureRandom.uuid
        logger = Logger.new(STDOUT, level: options.log_level, progname: "RES-Outbox #{consumer_uuid}")
        consumer_configuration = Configuration.new(
          split_keys: options.split_keys,
          message_format: options.message_format,
          batch_size: options.batch_size,
          database_url: options.database_url,
          redis_url: options.redis_url,
          cleanup: options.cleanup_strategy,
          cleanup_limit: options.cleanup_limit,
          sleep_on_empty: options.sleep_on_empty,
          locking: options.locking
        )
        metrics = Metrics.from_url(options.metrics_url)
        outbox_consumer =
          Outbox::Consumer.new(consumer_uuid, consumer_configuration, logger: logger, metrics: metrics)
        Runner.new(outbox_consumer, consumer_configuration, logger: logger)
      end
    end
  end
end
