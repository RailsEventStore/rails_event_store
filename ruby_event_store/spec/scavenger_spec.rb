# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Scavenger
    ::RSpec.describe Policy do
      specify "links only" do
        expect(Policy.links_only).to eq(Policy.new(name: :links_only))
        expect(Policy.links_only.name).to eq(:links_only)
      end

      specify "purge" do
        expect(Policy.purge).to eq(Policy.new(name: :purge))
        expect(Policy.purge.name).to eq(:purge)
      end

      specify "names" do
        expect(Policy::NAMES).to eq(%i[links_only purge])
      end

      specify "of a policy, a symbol or a string" do
        expect(Policy.of(:links_only)).to eq(Policy.links_only)
        expect(Policy.of("links_only")).to eq(Policy.links_only)
        expect(Policy.of(:purge)).to eq(Policy.purge)
        expect(Policy.of("purge")).to eq(Policy.purge)
      end

      specify "of a policy returns it" do
        policy = Policy.links_only

        expect(Policy.of(policy)).to equal(policy)
      end

      specify "of an unknown name" do
        expect { Policy.of(:delete) }.to raise_error(InvalidPolicy, "Unknown scavenger policy: :delete")
        expect { Policy.of("links-only") }.to raise_error(InvalidPolicy, 'Unknown scavenger policy: "links-only"')
        expect { Policy.of(nil) }.to raise_error(InvalidPolicy, "Unknown scavenger policy: nil")
      end

      specify "new with an unknown name" do
        expect { Policy.new(name: :delete) }.to raise_error(InvalidPolicy, "Unknown scavenger policy: :delete")
        expect { Policy.new(name: "links_only") }.to raise_error(
          InvalidPolicy,
          'Unknown scavenger policy: "links_only"',
        )
      end

      specify "invalid policy is a RubyEventStore error" do
        expect(InvalidPolicy.ancestors).to include(Error)
      end

      specify "purge?" do
        expect(Policy.purge.purge?).to be(true)
        expect(Policy.links_only.purge?).to be(false)
      end

      specify "to_s" do
        expect(Policy.links_only.to_s).to eq("links_only")
        expect(Policy.purge.to_s).to eq("purge")
      end

      specify "is frozen" do
        expect(Policy.links_only).to be_frozen
      end
    end

    ::RSpec.describe Plan do
      let(:stream) { Stream.new("Order$1") }

      def plan(to_mark:, to_sweep:)
        Plan.new(stream: stream, boundary: nil, reasons: [], to_mark: to_mark, to_sweep: to_sweep, to_purge: 0)
      end

      specify "empty" do
        expect(plan(to_mark: 0, to_sweep: 0)).to be_empty
        expect(plan(to_mark: 1, to_sweep: 0)).not_to be_empty
        expect(plan(to_mark: 0, to_sweep: 1)).not_to be_empty
      end

      specify "reasons" do
        expect(Plan::REASONS).to eq(%i[truncate_before soft_delete max_count max_age])
      end
    end

    ::RSpec.describe Report do
      def result(name, marked, swept, purged = 0)
        Report::StreamResult.new(
          stream: Stream.new(name),
          reasons: [:max_count],
          marked: marked,
          swept: swept,
          purged: purged,
        )
      end

      specify "totals" do
        report =
          Report.new(
            policy: Policy.links_only,
            dry_run: true,
            outcome: :finished,
            streams: [result("a", 3, 1, 1), result("b", 2, 5, 4)],
          )

        expect(report.marked).to eq(5)
        expect(report.swept).to eq(6)
        expect(report.purged).to eq(5)
      end

      specify "totals of no streams" do
        report = Report.new(policy: Policy.links_only, dry_run: false, outcome: :locked, streams: [])

        expect(report.marked).to eq(0)
        expect(report.swept).to eq(0)
        expect(report.purged).to eq(0)
      end
    end
  end
end
