require 'spec_helper'

module RubyEventStore
  module Mappers
    RSpec.describe NullMapper do
      let(:data)         { {some_attribute: 5} }
      let(:metadata)     { {some_meta: 1} }
      let(:event_id)     { SecureRandom.uuid }
      let(:domain_event) { SomethingHappened.new(data: data, metadata: metadata, event_id: event_id) }

      specify '#event_to_serialized_record' do
        record = subject.event_to_serialized_record(domain_event)

        expect(record.event_id).to   eq(domain_event.event_id)
        expect(record.data).to       eq(domain_event.data)
        expect(record.metadata).to   eq(domain_event.metadata)
      end

      specify '#serialized_record_to_event' do
        event = subject.serialized_record_to_event(domain_event)

        expect(event).to           eq(domain_event)
        expect(event.event_id).to  eq(domain_event.event_id)
        expect(event.data).to      eq(domain_event.data)
        expect(event.metadata).to  eq(domain_event.metadata)
      end

      specify "returns same object" do
        event = subject.serialized_record_to_event(
          subject.event_to_serialized_record(domain_event)
        )
        expect(event.object_id).to eq(domain_event.object_id)
      end
    end
  end
end
