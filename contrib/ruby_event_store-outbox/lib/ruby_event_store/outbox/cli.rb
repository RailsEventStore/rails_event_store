require "optparse"

module RubyEventStore
  module Outbox
    module CLI
      Options = Struct.new(:database_url, :redis_url)

      class Parser
        def self.parse(argv)
          options = Options.new(nil, nil)
          OptionParser.new do |option_parser|
            option_parser.banner = "Usage: res_outbox [options]"

            option_parser.on("--database-url=DATABASE_URL", "Database where outbox table is stored") do |database_url|
              options.database_url = database_url
            end

            option_parser.on("--redis-url=REDIS_URL", "URL to redis database") do |redis_url|
              options.redis_url = redis_url
            end
          end.parse(argv)
          return options
        end
      end
    end
  end
end
