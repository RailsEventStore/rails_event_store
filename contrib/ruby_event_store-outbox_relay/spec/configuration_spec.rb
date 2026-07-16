# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe Configuration do
      around do |example|
        original_build_block = Configuration.instance_variable_get(:@build_block)
        example.run
      ensure
        Configuration.instance_variable_set(:@build_block, original_build_block)
      end

      specify "build raises NotConfigured with a helpful message when configure was never called" do
        Configuration.instance_variable_set(:@build_block, nil)

        expect { Configuration.build }.to raise_error(
          Configuration::NotConfigured,
          "call RubyEventStore::OutboxRelay::Configuration.configure first",
        )
      end

      specify "build does not raise once configure has been called" do
        Configuration.configure { double(:relay) }

        expect { Configuration.build }.not_to raise_error
      end

      specify "configure stores the block, and build calls it with the given overrides, returning its result" do
        received_overrides = nil
        relay_double = double(:relay)
        Configuration.configure do |**overrides|
          received_overrides = overrides
          relay_double
        end

        result = Configuration.build(batch_size: 50, poll_interval: 2.0, logger: :some_logger)

        expect(received_overrides).to eq(batch_size: 50, poll_interval: 2.0, logger: :some_logger)
        expect(result).to eq(relay_double)
      end
    end
  end
end
