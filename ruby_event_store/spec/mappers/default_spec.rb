SomethingHappened = Class.new(RubyEventStore::Event)

module RubyEventStore
  module Mappers
    RSpec.describe Default do
      let(:data)   {{some_attribute: 5}}
      let(:metadata)     {{some_meta: 1}}
      let(:domain_event) { SomethingHappened.new(data: data, metadata: metadata) }

      specify '#event_to_serialized_record returns YAML serialized record' do
        record = subject.event_to_serialized_record(domain_event)
        expect(record).to            be_a SerializedRecord
        expect(record.id).to         eq domain_event.event_id
        expect(record.metadata).to   eq YAML.dump(metadata)
        expect(record.data).to       eq YAML.dump(data)
        expect(record.event_type).to eq SomethingHappened
      end

      specify '#serialized_record_to_event returns event instance' do
        record = SerializedRecord.new(
          id:         domain_event.event_id,
          data:       YAML.dump(data),
          metadata:   YAML.dump(metadata),
          event_type: SomethingHappened.name
        )
        event = subject.serialized_record_to_event(record)
        expect(event).to              be_a SomethingHappened
        expect(event.event_id).to     eq domain_event.event_id
        expect(event.data).to         eq(data)
        expect(event.metadata).to     eq(metadata)
      end

      specify '#serialized_record_to_event its using events class remapping' do
        subject = described_class.new(events_class_remapping: {'EventNameBeforeRefactor' => 'SomethingHappened'})
        record = SerializedRecord.new(
          id:         domain_event.event_id,
          data:       YAML.dump(data),
          metadata:   YAML.dump(metadata),
          event_type: "EventNameBeforeRefactor"
        )
        event = subject.serialized_record_to_event(record)
        expect(event).to be_a SomethingHappened
      end
    end
  end
end
