require 'spec_helper'

SomethingHappened = Class.new(RubyEventStore::Event)

module RubyEventStore
  module Mappers
    RSpec.describe Default do
      let(:data)         { {some_attribute: 5} }
      let(:metadata)     { {some_meta: 1} }
      let(:event_id)     { SecureRandom.uuid }
      let(:domain_event) { SomethingHappened.new(data: data, metadata: metadata, event_id: event_id) }

      specify '#event_to_serialized_record returns YAML serialized record' do
        record = subject.event_to_serialized_record(domain_event)
        expect(record).to            be_a SerializedRecord
        expect(record.event_id).to   eq event_id
        expect(record.data).to       eq "---\n:some_attribute: 5\n"
        expect(record.metadata).to   eq "---\n:some_meta: 1\n"
        expect(record.event_type).to eq "SomethingHappened"
      end

      specify '#serialized_record_to_event returns event instance' do
        record = SerializedRecord.new(
          event_id:   domain_event.event_id,
          data:       "---\n:some_attribute: 5\n",
          metadata:   "---\n:some_meta: 1\n",
          event_type: SomethingHappened.name
        )
        event = subject.serialized_record_to_event(record)
        expect(event).to              eq(domain_event)
        expect(event.event_id).to     eq domain_event.event_id
        expect(event.data).to         eq(data)
        expect(event.metadata).to     eq(metadata)
      end

      specify '#serialized_record_to_event its using events class remapping' do
        subject = described_class.new(events_class_remapping: {'EventNameBeforeRefactor' => 'SomethingHappened'})
        record = SerializedRecord.new(
          event_id:   domain_event.event_id,
          data:       "---\n:some_attribute: 5\n",
          metadata:   "---\n:some_meta: 1\n",
          event_type: "EventNameBeforeRefactor"
        )
        event = subject.serialized_record_to_event(record)
        expect(event).to eq(domain_event)
      end

      specify '#add_metadata' do
        subject.add_metadata(domain_event, :yo, 123)
        expect(domain_event.metadata.fetch(:yo)).to eq(123)

        subject.add_metadata(domain_event, 'lo', 456)
        expect(domain_event.metadata.fetch(:lo)).to eq(456)
      end

      context 'when custom serializer is provided' do
        class ExampleYamlSerializer
          def self.load(value)
            YAML.load(decrypt(value))
          end

          def self.dump(value)
            encrypt(YAML.dump(value))
          end

          private

          def self.encrypt(value)
            value.reverse
          end

          def self.decrypt(value)
            value.reverse
          end
        end

        let(:custom_serializer) { ExampleYamlSerializer }
        subject { described_class.new(serializer: custom_serializer) }

        specify '#event_to_serialized_record returns serialized record' do
          record = subject.event_to_serialized_record(domain_event)
          expect(record).to            be_a SerializedRecord
          expect(record.event_id).to   eq event_id
          expect(record.data).to       eq "\n5 :etubirtta_emos:\n---"
          expect(record.metadata).to   eq "\n1 :atem_emos:\n---"
          expect(record.event_type).to eq "SomethingHappened"
        end

        specify '#serialized_record_to_event returns event instance' do
          record = SerializedRecord.new(
            event_id:   domain_event.event_id,
            data:       "\n5 :etubirtta_emos:\n---",
            metadata:   "\n1 :atem_emos:\n---",
            event_type: SomethingHappened.name
          )
          event = subject.serialized_record_to_event(record)
          expect(event).to              eq(domain_event)
          expect(event.event_id).to     eq domain_event.event_id
          expect(event.data).to         eq(data)
          expect(event.metadata).to     eq(metadata)
        end
      end
    end
  end
end
