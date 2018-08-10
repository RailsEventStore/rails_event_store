require 'spec_helper'
require 'time'

module RubyEventStore
  RSpec.describe CorrelatedMessages do

    specify "correlate metadata" do
      event  = Event.new(event_id: "one", data: nil)
      result = CorrelatedMessages.metadata_for(event)

      expect(result[:correlation_id]).to eq("one")
      expect(result[:causation_id]).to eq("one")

      e2  = Event.new(event_id: "one", metadata: {correlation_id: "two"}, data: nil)
      r2 = CorrelatedMessages.metadata_for(e2)

      expect(r2[:correlation_id]).to eq("two")
      expect(r2[:causation_id]).to eq("one")
    end

  end
end
