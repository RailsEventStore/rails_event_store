# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Mappers
    ::RSpec.describe BatchMapper do
      Type1 = Class.new(RubyEventStore::Event)
      Type2 = Class.new(RubyEventStore::Event)
      Type3 = Class.new(RubyEventStore::Event)
      let(:events) { [Type1.new(data: { value: 1 }), Type2.new(data: { value: 2 }), Type3.new(data: { value: 3 })] }
      let(:records) { events.map { |event| Default.new.event_to_record(event) } }

      specify "deserialize & serialize records" do
        mapper = BatchMapper.new
        serialized_records = mapper.records_to_events(records)
        expect(mapper.events_to_records(serialized_records)).to eq(records)
      end

      specify "use batch mapping with custom mapper" do
        item_mapper = Class.new { def record_to_event(record) = record.event_id }.new
        mapper = BatchMapper.new(item_mapper)
        expect(mapper.records_to_events(records)).to eq(records.map(&:event_id))
      end
    end
  end
end
