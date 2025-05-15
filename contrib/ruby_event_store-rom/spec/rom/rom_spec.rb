# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ROM
    ::RSpec.describe "setup" do
      specify "via database URL", mutant: "RubyEventStore::ROM.setup" do
        skip if /json/.match?(ENV["DATA_TYPE"])

        config = ::ROM::Configuration.new(:sql, "sqlite://tmp/dummy.db")
        config.default.run_migrations

        rom = ROM.setup(:sql, "sqlite://tmp/dummy.db")
        expect(rom.gateways.fetch(:default).connection.database_type).to eq(:sqlite)
      end

      specify "via ROM configuration", mutant: "RubyEventStore::ROM.setup" do
        skip if /json/.match?(ENV["DATA_TYPE"])

        config = ::ROM::Configuration.new(:sql, "sqlite::memory:")
        config.default.run_migrations

        rom = ::RubyEventStore::ROM.setup(config)
        expect(rom.gateways.fetch(:default).connection.database_type).to eq(:sqlite)
      end
    end
  end
end
