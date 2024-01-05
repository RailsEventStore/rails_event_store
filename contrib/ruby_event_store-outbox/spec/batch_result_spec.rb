# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Outbox
    ::RSpec.describe BatchResult do
      specify "::empty" do
        batch_result = BatchResult.empty

        expect(batch_result.failed_count).to eq(0)
        expect(batch_result.success_count).to eq(0)
      end

      specify "adding updated element" do
        batch_result = BatchResult.empty

        batch_result.count_success!

        expect(batch_result.success_count).to eq(1)
      end

      specify "adding failed element" do
        batch_result = BatchResult.empty

        batch_result.count_failed!

        expect(batch_result.failed_count).to eq(1)
      end
    end
  end
end
