# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module OutboxRelay
    ::RSpec.describe WithoutRelay do
      specify "is inactive by default" do
        expect(WithoutRelay.active?).to eq(false)
      end

      specify "is active for the duration of the block, then reverts to inactive" do
        active_inside = nil

        WithoutRelay.call { active_inside = WithoutRelay.active? }

        expect(active_inside).to eq(true)
        expect(WithoutRelay.active?).to eq(false)
      end

      specify "reverts to inactive even when the block raises" do
        expect { WithoutRelay.call { raise "boom" } }.to raise_error("boom")

        expect(WithoutRelay.active?).to eq(false)
      end

      specify "restores the previous state after a nested call, not unconditionally false" do
        active_after_nested = nil

        WithoutRelay.call { WithoutRelay.call {}; active_after_nested = WithoutRelay.active? }

        expect(active_after_nested).to eq(true)
        expect(WithoutRelay.active?).to eq(false)
      end

      specify "is scoped per thread" do
        active_on_other_thread = nil

        WithoutRelay.call { Thread.new { active_on_other_thread = WithoutRelay.active? }.join }

        expect(active_on_other_thread).to eq(false)
      end
    end
  end
end
