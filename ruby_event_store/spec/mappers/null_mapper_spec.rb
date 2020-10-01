require 'spec_helper'
require 'ruby_event_store/spec/mapper_lint'

module RubyEventStore
  module Mappers
    RSpec.describe NullMapper do
      let(:time)         { Time.now.utc }
      let(:data)         { {some_attribute: 5} }
      let(:metadata)     { {some_meta: 1} }
      let(:event_id)     { SecureRandom.uuid }
      let(:domain_event) { TimeEnrichment.with(TestEvent.new(data: data, metadata: metadata, event_id: event_id), timestamp: time, valid_at: time) }

      it_behaves_like :mapper, NullMapper.new, TimeEnrichment.with(TestEvent.new)

      specify '#event_to_record' do
        record = subject.event_to_record(domain_event)

        expect(record.event_id).to      eq(domain_event.event_id)
        expect(record.data).to          eq(domain_event.data)
        expect(record.metadata.to_h).to eq(metadata)
        expect(record.event_type).to    eq("TestEvent")
        expect(record.timestamp).to     eq(time)
        expect(record.valid_at).to      eq(time)
      end

      specify '#record_to_event' do
        record = subject.event_to_record(domain_event)
        event  = subject.record_to_event(record)

        expect(event).to               eq(domain_event)
        expect(event.event_id).to      eq(domain_event.event_id)
        expect(event.data).to          eq(domain_event.data)
        expect(event.metadata.to_h).to eq(domain_event.metadata.to_h)
        expect(event.event_type).to    eq("TestEvent")
        expect(event.timestamp).to     eq(time)
        expect(event.valid_at).to      eq(time)
      end
    end
  end
end
