module RubyEventStore
  RSpec.shared_examples :mapper do |mapper, domain_event|
    specify "event_to_serialized_record returns instance of Record" do
      record = mapper.event_to_serialized_record(domain_event)

      expect(record).to            be_kind_of(Record)
      expect(record.event_id).to   eq(domain_event.event_id)
      expect(record.event_type).to eq(domain_event.event_type)
    end

    specify "serialize and deserialize gives equal event" do
      record = mapper.event_to_serialized_record(domain_event)

      expect(mapper.serialized_record_to_event(record)).to eq(domain_event)
    end
  end
end
