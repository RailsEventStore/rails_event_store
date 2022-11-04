require "spec_helper"

module RubyEventStore
  module Outbox
    RSpec.describe BatchResult do
      specify "::empty" do
        batch_result = BatchResult.empty

        expect(batch_result.failed_record_ids).to eq([])
        expect(batch_result.updated_record_ids).to eq([])
      end
    end
  end
end
