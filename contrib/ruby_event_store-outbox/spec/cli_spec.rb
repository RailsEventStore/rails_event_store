require 'spec_helper'

module RubyEventStore
  module Outbox
    class CLI
      RSpec.describe Parser do
        specify "#parse storage urls" do
          argv = [
            '--database-url=mysql2://root@0.0.0.0:3306/dbname',
            '--redis-url=redis://localhost:6379/0',
          ]

          options = Parser.parse(argv)

          expect(options.database_url).to eq("mysql2://root@0.0.0.0:3306/dbname")
          expect(options.redis_url).to eq("redis://localhost:6379/0")
        end

        specify "#parse log levels" do
          expect(Parser.parse(["--log-level=fatal"]).log_level).to eq(:fatal)
          expect(Parser.parse(["--log-level=error"]).log_level).to eq(:error)
          expect(Parser.parse(["--log-level=warn"]).log_level).to eq(:warn)
          expect(Parser.parse(["--log-level=info"]).log_level).to eq(:info)
          expect(Parser.parse(["--log-level=debug"]).log_level).to eq(:debug)
          expect(Parser.parse([]).log_level).to eq(:warn)
          expect do
            Parser.parse(["--log-level=rubbish"])
          end.to raise_error(OptionParser::InvalidArgument)
        end

        specify "#parse split keys" do
          expect(Parser.parse(["--split-keys=foo"]).split_keys).to eq(["foo"])
          expect(Parser.parse(["--split-keys=foo,bar"]).split_keys).to eq(["foo", "bar"])
          expect(Parser.parse(["--split-keys="]).split_keys).to eq(nil)
          expect(Parser.parse([]).split_keys).to eq(nil)
        end

        specify "#parse format" do
          expect(Parser.parse(["--message-format=sidekiq5"]).message_format).to eq("sidekiq5")
          expect do
            Parser.parse(["--message-format=rubbish"])
          end.to raise_error(OptionParser::InvalidArgument)
        end

        specify "#parse --batch-size" do
          expect(Parser.parse(["--batch-size=20"]).batch_size).to eq(20)
          expect(Parser.parse([]).batch_size).to eq(100)
        end

        specify "#parse --metrics-url" do
          expect(Parser.parse(["--metrics-url=http://username:password@host:1234/db"]).metrics_url).to eq("http://username:password@host:1234/db")
          expect(Parser.parse([]).metrics_url).to eq(nil)
        end
      end
    end
  end
end
