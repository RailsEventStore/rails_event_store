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

      specify "build refuses a block that can't take an override, instead of ignoring the option without a word" do
        Configuration.configure { double(:relay) }

        expect { Configuration.build(batch_size: 50, logger: :some_logger) }.to raise_error(
          ArgumentError,
          "the configure block ignores batch_size, logger: declare them, or take **options and pass them on to Relay.new",
        )
      end

      specify "build names only the overrides the block can't take" do
        Configuration.configure { |batch_size:, logger:| double(:relay) }

        expect { Configuration.build(batch_size: 50, poll_interval: 2.0, logger: :some_logger) }.to raise_error(
          ArgumentError,
          /ignores poll_interval:/,
        )
      end

      specify "build doesn't take a positional parameter for a keyword, whatever it is called" do
        Configuration.configure { |batch_size, *rest| double(:relay) }

        expect { Configuration.build(batch_size: 50) }.to raise_error(ArgumentError, /ignores batch_size:/)
      end

      specify "build accepts a block that declares every override" do
        received = nil
        Configuration.configure do |batch_size: 1, logger: nil|
          received = [batch_size, logger]
          double(:relay)
        end

        Configuration.build(batch_size: 50, logger: :some_logger)

        expect(received).to eq([50, :some_logger])
      end

      specify "build accepts an override the block takes through optional keywords too" do
        Configuration.configure { |batch_size: 1| double(:relay) }

        expect { Configuration.build(batch_size: 50) }.not_to raise_error
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
