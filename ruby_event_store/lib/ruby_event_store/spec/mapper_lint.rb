# frozen_string_literal: true

module RubyEventStore
  ::RSpec.shared_examples "mapper" do |mapper, event|
    specify "event_to_record returns instance of Record" do
      record = mapper.event_to_record(event)

      expect(record).to be_a(Record)
      expect(record.event_id).to eq(event.event_id)
      expect(record.event_type).to eq(event.event_type)
    end

    specify "serialize and deserialize gives equal event" do
      record = mapper.event_to_record(event)

      expect(mapper.record_to_event(record)).to eq(event)
    end
  end
end
