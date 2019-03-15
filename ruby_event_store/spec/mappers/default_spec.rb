require 'spec_helper'
require 'json'

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
        expect(event.metadata.to_h).to     eq(metadata)
      end

      specify '#serialized_record_to_event its using events class remapping' do
        silence_warnings do
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
      end

      specify '#serialized_record_to_event its using events class remapping prints deprecation message' do
        expect { described_class.new(events_class_remapping: {'EventNameBeforeRefactor' => 'SomethingHappened'}) }.to output(<<~EOS).to_stderr
          events_class_remapping is deprecated. Provide custom event builder instead.
        EOS
      end

      specify '#serialized_record_to_event its using default (empty) events class remapping does not print deprecation message' do
        expect { described_class.new }.not_to output.to_stderr
      end

      specify '#serialized_record_to_event using default event builder returns event instance' do
        record = SerializedRecord.new(
          event_id:   domain_event.event_id,
          data:       "---\n:some_attribute: 5\n",
          metadata:   "---\n:some_meta: 1\n",
          event_type: SomethingHappened.name
        )
        subject = described_class.new(event_builder: RubyEventStore::Mappers::TypeToClass.new)
        event = subject.serialized_record_to_event(record)
        expect(event).to              eq(domain_event)
        expect(event.event_id).to     eq domain_event.event_id
        expect(event.data).to         eq(data)
        expect(event.metadata.to_h).to     eq(metadata)
      end

      specify '#serialized_record_to_event using custom event builder' do
        class CustomEventBuilder < TypeToClass
          def call(event_type)
            case event_type
              when 'EventNameBeforeRefactor'
                return SomethingHappened
              else super
            end
          end
        end
        subject = described_class.new(event_builder: CustomEventBuilder.new)
        record = SerializedRecord.new(
          event_id:   domain_event.event_id,
          data:       "---\n:some_attribute: 5\n",
          metadata:   "---\n:some_meta: 1\n",
          event_type: "EventNameBeforeRefactor"
        )
        event = subject.serialized_record_to_event(record)
        expect(event).to eq(domain_event)
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
          expect(event.metadata.to_h).to     eq(metadata)
        end
      end

      context 'when JSON serializer is provided' do
        subject { described_class.new(serializer: JSON) }

        specify '#event_to_serialized_record returns serialized record' do
          record = subject.event_to_serialized_record(domain_event)
          expect(record).to            be_a SerializedRecord
          expect(record.event_id).to   eq event_id
          expect(record.data).to       eq %q[{"some_attribute":5}]
          expect(record.metadata).to   eq %q[{"some_meta":1}]
          expect(record.event_type).to eq "SomethingHappened"
        end

        specify '#serialized_record_to_event returns event instance' do
          record = SerializedRecord.new(
            event_id:   domain_event.event_id,
            data:       %q[{"some_attribute":5}],
            metadata:   %q[{"some_meta":1}],
            event_type: SomethingHappened.name
          )
          domain_event = SomethingHappened.new(
            data: stringify(data),
            metadata: metadata,
            event_id: event_id
          )
          event = subject.serialized_record_to_event(record)
          expect(event).to              eq(domain_event)
          expect(event.event_id).to     eq domain_event.event_id
          expect(event.data).to         eq(domain_event.data)
          expect(event.metadata.to_h).to     eq(domain_event.metadata.to_h)
        end
      end

      private

      def stringify(hash)
        hash.each_with_object({}) do |(k, v), memo|
          memo[k.to_s] = v
        end
      end
    end
  end
end
