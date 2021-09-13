require "optparse"
require_relative "version"
require_relative "consumer"
require_relative "metrics"

module RubyEventStore
  module Outbox
    class CLI
      DEFAULTS = {
        database_url: nil,
        redis_url: nil,
        log_level: :warn,
        split_keys: nil,
        message_format: 'sidekiq5',
        batch_size: 100,
        metrics_url: nil,
        cleanup_strategy: :none,
        sleep_on_empty: 0.5
      }
      Options = Struct.new(*DEFAULTS.keys)

      class Parser
        def self.parse(argv)
          options = Options.new(*DEFAULTS.values)
          OptionParser.new do |option_parser|
            option_parser.banner = "Usage: res_outbox [options]"

            option_parser.on("--database-url=DATABASE_URL", "Database where outbox table is stored") do |database_url|
              options.database_url = database_url
            end

            option_parser.on("--redis-url=REDIS_URL", "URL to redis database") do |redis_url|
              options.redis_url = redis_url
            end

            option_parser.on("--log-level=LOG_LEVEL", [:fatal, :error, :warn, :info, :debug], "Logging level, one of: fatal, error, warn, info, debug. Default: warn") do |log_level|
              options.log_level = log_level.to_sym
            end

            option_parser.on("--message-format=FORMAT", ["sidekiq5"], "Message format, supported: sidekiq5. Default: sidekiq5") do |message_format|
              options.message_format = message_format
            end

            option_parser.on("--split-keys=SPLIT_KEYS", Array, "Split keys which should be handled, all if not specified") do |split_keys|
              options.split_keys = split_keys if !split_keys.empty?
            end

            option_parser.on("--batch-size=BATCH_SIZE", Integer, "Amount of records fetched in one fetch. Bigger value means more duplicated messages when network problems occur. Default: 100") do |batch_size|
              options.batch_size = batch_size
            end

            option_parser.on("--metrics-url=METRICS_URL", "URI to metrics collector, optional") do |metrics_url|
              options.metrics_url = metrics_url
            end

            option_parser.on("--cleanup=STRATEGY", "A strategy for cleaning old records. One of: none or iso8601 duration format how old enqueued records should be removed. Default: none") do |cleanup_strategy|
              options.cleanup_strategy = cleanup_strategy
            end

            option_parser.on("--sleep-on-empty=SLEEP_TIME", Float, "How long to sleep before next check when there was nothing to do. Default: 0.5") do |sleep_on_empty|
              options.sleep_on_empty = sleep_on_empty
            end

            option_parser.on_tail("--version", "Show version") do
              puts VERSION
              exit
            end
          end.parse(argv)
          return options
        end
      end

      def run(argv)
        options = Parser.parse(argv)
        outbox_consumer = build_consumer(options)
        outbox_consumer.init
        outbox_consumer.run
      end

      def build_consumer(options)
        consumer_uuid = SecureRandom.uuid
        logger = Logger.new(STDOUT, level: options.log_level, progname: "RES-Outbox #{consumer_uuid}")
        consumer_configuration = Consumer::Configuration.new(
          split_keys: options.split_keys,
          message_format: options.message_format,
          batch_size: options.batch_size,
          database_url: options.database_url,
          redis_url: options.redis_url,
          cleanup: options.cleanup_strategy,
          sleep_on_empty: options.sleep_on_empty,
        )
        metrics = Metrics.from_url(options.metrics_url)
        outbox_consumer = RubyEventStore::Outbox::Consumer.new(
          consumer_uuid,
          consumer_configuration,
          logger: logger,
          metrics: metrics,
        )
      end
    end
  end
end
