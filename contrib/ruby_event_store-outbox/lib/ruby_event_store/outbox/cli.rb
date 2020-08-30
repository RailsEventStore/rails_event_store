require "optparse"
require "ruby_event_store/outbox/version"
require "ruby_event_store/outbox/consumer"
require "ruby_event_store/outbox/metrics"

module RubyEventStore
  module Outbox
    class CLI
      Options = Struct.new(:database_url, :redis_url, :log_level, :split_keys, :message_format, :batch_size, :metrics_url)

      class Parser
        def self.parse(argv)
          options = Options.new(nil, nil, :warn, nil, nil, 100)
          OptionParser.new do |option_parser|
            option_parser.banner = "Usage: res_outbox [options]"

            option_parser.on("--database-url DATABASE_URL", "Database where outbox table is stored") do |database_url|
              options.database_url = database_url
            end

            option_parser.on("--redis-url REDIS_URL", "URL to redis database") do |redis_url|
              options.redis_url = redis_url
            end

            option_parser.on("--log-level LOG_LEVEL", [:fatal, :error, :warn, :info, :debug], "Logging level, one of: fatal, error, warn, info, debug") do |log_level|
              options.log_level = log_level.to_sym
            end

            option_parser.on("--message-format FORMAT", ["sidekiq5"], "Message format, supported: sidekiq5") do |message_format|
              options.message_format = message_format
            end

            option_parser.on("--split-keys=split_keys", Array, "Split keys which should be handled, all if not specified") do |split_keys|
              options.split_keys = split_keys if !split_keys.empty?
            end

            option_parser.on("--batch-size BATCH_SIZE", Integer, "Amount of records fetched in one fetch. Bigger value means more duplicated messages when network problems occur.") do |batch_size|
              options.batch_size = batch_size
            end

            option_parser.on("--metrics-url METRICS_URL", "URI to metrics collector") do |metrics_url|
              options.metrics_url = metrics_url
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
        )
        metrics = Metrics.from_url(options.metrics_url)
        outbox_consumer = RubyEventStore::Outbox::Consumer.new(
          consumer_uuid,
          options,
          logger: logger,
          metrics: metrics,
        )
      end
    end
  end
end
