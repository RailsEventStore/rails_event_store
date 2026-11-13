# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe "systemd unit template", mutant: false do
      let(:unit) { File.read(File.expand_path("../support/systemd/res-outbox-relay.service", __dir__)) }

      specify "keeps the database URL out of the command line, reading it from an environment file" do
        expect(unit).to match(%r{^EnvironmentFile=/etc/\S+$})
        expect(unit).not_to include("--database-url")
        expect(unit).not_to include("${DATABASE_URL}")
      end

      %w[
        NoNewPrivileges=true
        PrivateTmp=true
        ProtectSystem=strict
        ProtectKernelTunables=true
        RestrictSUIDSGID=true
        LockPersonality=true
      ].each { |setting| specify("hardens with #{setting}") { expect(unit).to match(/^#{Regexp.escape(setting)}$/) } }

      specify "drops every capability" do
        expect(unit).to match(/^CapabilityBoundingSet=$/)
      end

      specify "is documented in English" do
        expect(unit).not_to match(/[ąćęłńóśźż]/i)
      end
    end
  end
end
