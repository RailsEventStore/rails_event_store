module RubyEventStore
  module Mappers
    RSpec.describe Default do
      SomethingHappened = Class.new(RubyEventStore::Event)
      let(:data)   {{some_attribute: 5}}
      let(:metadata)     {{some_meta: 1}}
      let(:event_id)     { SecureRandom.uuid }
      let(:domain_event) { SomethingHappened.new(data: data, metadata: metadata) }

      specify '#event_to_serialized_record returns YAML serialized record' do
        record = subject.event_to_serialized_record(domain_event)
        expect(record).to          be_a SerializedRecord
        expect(record.id).not_to   be_nil
        expect(record.metadata).to eq YAML.dump(metadata)
        expect(record.data).to     eq YAML.dump(data)
      end

      specify '#serialized_record_to_event returns event instance' do
        record = SerializedRecord.new(
          id:         event_id,
          data:       YAML.dump(data),
          metadata:   YAML.dump(metadata),
          event_type: SomethingHappened.name
        )
        event = subject.serialized_record_to_event(record)
        expect(event).to              be_a SomethingHappened
        expect(event.event_id).not_to be_nil
        expect(event.data).to         eq(data)
        expect(event.metadata).to     eq(metadata)
      end

      specify 'when serializer is not following contract' do
        expect do
          described_class.new(serializer: double)
        end.to raise_error Default::WrongSerializer
      end

      specify 'when events_class_remapping is not following contract' do
        expect do
          described_class.new(events_class_remapping: double)
        end.to raise_error ArgumentError
      end
    end
  end
end
