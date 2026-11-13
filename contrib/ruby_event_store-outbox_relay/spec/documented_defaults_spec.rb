# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/outbox_relay/cli"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe "the documented defaults", mutant: false do
      let(:relay_options) do
        {
          "batch_size" => Relay::DEFAULT_BATCH_SIZE,
          "poll_interval" => Relay::DEFAULT_POLL_INTERVAL,
          "lease_duration" => Relay::DEFAULT_LEASE_DURATION,
        }
      end
      let(:cli_options) do
        {
          "--batch-size" => Relay::DEFAULT_BATCH_SIZE,
          "--poll-interval" => Relay::DEFAULT_POLL_INTERVAL,
          "--lease-duration" => Relay::DEFAULT_LEASE_DURATION,
          "--stats-interval" => Relay::DEFAULT_STATS_INTERVAL,
        }
      end
      let(:root) { File.expand_path("..", __dir__) }
      let(:site_page) { File.expand_path("../../railseventstore.org/docs/advanced-topics/outbox-relay.md", root) }

      def table_default(text, option)
        text[/^\|\s*`#{Regexp.escape(option)}`\s*\|\s*(?:no\s*\|\s*)?([^|\s]+)\s*\|/, 1]
      end

      specify "Relay takes them as its argument defaults" do
        relay = Relay.new(client: double(:client, outbox: nil, async_subscriptions: nil))

        expect(relay.instance_variable_get(:@batch_size)).to eq(Relay::DEFAULT_BATCH_SIZE)
        expect(relay.instance_variable_get(:@poll_interval)).to eq(Relay::DEFAULT_POLL_INTERVAL)
        expect(relay.instance_variable_get(:@lease_duration)).to eq(Relay::DEFAULT_LEASE_DURATION)
        expect(relay.instance_variable_get(:@stats_interval)).to eq(Relay::DEFAULT_STATS_INTERVAL)
      end

      specify "--help quotes them" do
        output = StringIO.new
        $stdout = output
        begin
          CLI::Parser.parse(["--help"])
        rescue SystemExit
        ensure
          $stdout = STDOUT
        end

        cli_options.each do |option, default|
          line = output.string.lines.each_cons(3).find { |lines| lines.first.include?(option) }&.join
          expect(line).to match(/Default: #{default}\b/), option
        end
      end

      specify "the README table quotes them" do
        readme = File.read(File.join(root, "README.md"))

        relay_options.each { |option, default| expect(table_default(readme, option)).to eq(default.to_s), option }
      end

      specify "the documentation on the site quotes them, for the Relay and for the command line" do
        skip "the site is not part of the gem" unless File.exist?(site_page)
        page = File.read(site_page)

        relay_options.each { |option, default| expect(table_default(page, option)).to eq(default.to_s), option }
        cli_options.each { |option, default| expect(table_default(page, option)).to eq(default.to_s), option }
      end
    end
  end
end
