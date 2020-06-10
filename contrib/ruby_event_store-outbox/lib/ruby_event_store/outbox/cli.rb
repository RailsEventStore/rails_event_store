require "optparse"
require "ruby_event_store/outbox/consumer"

module RubyEventStore
  module Outbox
    class CLI
      Options = Struct.new(:database_url, :redis_url, :log_level, :split_keys)

      class Parser
        def self.parse(argv)
          options = Options.new(nil, nil, :warn, nil)
          OptionParser.new do |option_parser|
            option_parser.banner = "Usage: res_outbox [options]"

            option_parser.on("--database-url=DATABASE_URL", "Database where outbox table is stored") do |database_url|
              options.database_url = database_url
            end

            option_parser.on("--redis-url=REDIS_URL", "URL to redis database") do |redis_url|
              options.redis_url = redis_url
            end

            option_parser.on("--log-level=log_level", [:fatal, :error, :warn, :info, :debug], "Logging level, one of: fatal, error, warn, info, debug") do |log_level|
              options.log_level = log_level.to_sym
            end

            option_parser.on("--split-keys=split_keys", Array, "Split keys which should be handled, all if not specified") do |split_keys|
              options.split_keys = split_keys if !split_keys.empty?
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
        logger = Logger.new(STDOUT)
        logger.level = options.log_level
        outbox_consumer = RubyEventStore::Outbox::Consumer.new(
          options.split_keys,
          database_url: options.database_url,
          redis_url: options.redis_url,
          logger: logger,
        )
        outbox_consumer.init
        outbox_consumer.run
      rescue Interrupt
        logger.info 'Interrupted, shutting down'
        exit(0)
      end
    end
  end
end
