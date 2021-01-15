# frozen_string_literal: true

require 'spec_helper'

module RubyEventStore
  module Transformations
    RSpec.describe IdentityMap do
      DummyEvent = Class.new(RubyEventStore::Event)

      specify do
        event = TimeEnrichment.with(DummyEvent.new)
        map   = IdentityMap.new
        transformed_event = map.load(map.dump(event))

        expect(event).to equal(transformed_event)
        expect(event.metadata).to  eq(transformed_event.metadata)
        expect(event.data).to      eq(transformed_event.data)
      end

      specify do
        event  = TimeEnrichment.with(DummyEvent.new, timestamp: time = Time.new.utc)
        map    = IdentityMap.new
        record = map.dump(event)

        expect(record.timestamp).to eq(time)
        expect(record.valid_at).to  eq(time)
        expect(record.data).to      eq({})
        expect(record.metadata).to  eq({})
      end
    end
  end
end
