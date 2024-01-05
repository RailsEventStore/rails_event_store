# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Browser do
    let(:timestamp) { Time.utc(2020, 1, 1, 12, 0, 0, 1) }
    let(:parent_event) { TimeEnrichment.with(DummyEvent.new, timestamp: timestamp) }
    let(:dummy_event) { TimeEnrichment.with(DummyEvent.new, timestamp: timestamp) }

    specify "without persisted correlation_id" do
      json_event = Browser::JsonApiEvent.new(dummy_event, parent_event).to_h
      expect(json_event["correlation_stream_name"]).to be_nil
    end
  end
end
