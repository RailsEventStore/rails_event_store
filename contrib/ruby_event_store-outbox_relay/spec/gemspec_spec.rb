# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe "the gemspec", mutant: false do
      let(:root) { File.expand_path("..", __dir__) }
      let(:gemspec) { Dir.chdir(root) { Gem::Specification.load("ruby_event_store-outbox_relay.gemspec") } }

      specify "packages everything it declares and the README points to" do
        expect(gemspec.files).to include(
          "bin/res_outbox_relay",
          "support/systemd/res-outbox-relay.service",
          "README.md",
          "lib/ruby_event_store/outbox_relay.rb",
        )
        expect(gemspec.executables).to eq(["res_outbox_relay"])
        expect(gemspec.files).to include("#{gemspec.bindir}/#{gemspec.executables.first}")
      end

      specify "describes the current design, not the column it once used" do
        expect(gemspec.summary).not_to include("published_at")
        expect(gemspec.summary).to include("outbox")
      end
    end
  end
end
