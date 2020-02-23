# frozen_string_literal: true

require 'spec_helper'
require 'ruby_event_store/spec/mapper_lint'

SomethingHappenedJSON = Class.new(RubyEventStore::Event)

module RubyEventStore
  module Mappers
    RSpec.describe JSONMapper do
      it_behaves_like :mapper, described_class.new, TimestampEnrichment.with_timestamp(SomethingHappenedJSON.new)

      let(:data) { { some_attribute: 5 } }
      let(:metadata) { { some_meta: 1 } }
      let(:event_id) { SecureRandom.uuid }
      let(:serialized_record_event_type) { SomethingHappenedJSON.name }
      let(:domain_event) do
        SomethingHappenedJSON.new(
          event_id: event_id,
          data:     data,
          metadata: metadata,
        )
      end
      let(:serialized_record) do
        SerializedRecord.new(
          event_id:   event_id,
          data:       data,
          metadata:   metadata,
          event_type: serialized_record_event_type,
        )
      end

      describe '#event_to_serialized_record' do
        subject do
          described_class.new.event_to_serialized_record(domain_event)
        end

        it { is_expected.to be_a(SerializedRecord) }
        it { is_expected.to have_attributes(event_id: serialized_record.event_id) }
        it { is_expected.to have_attributes(data: serialized_record.data) }
        it { is_expected.to have_attributes(metadata: serialized_record.metadata) }
        it { is_expected.to have_attributes(event_type: serialized_record.event_type) }
      end

      describe '#serialized_record_to_event' do
        subject(:serialized_record_to_event) do
          described_class.new.serialized_record_to_event(serialized_record)
        end

        it { is_expected.to eq(domain_event) }
        it { is_expected.to be_a(SomethingHappenedJSON) }
        it { is_expected.to have_attributes(event_id: domain_event.event_id) }
        it { is_expected.to have_attributes(data: domain_event.data) }
        it 'includes the expected metadata' do
          expect(serialized_record_to_event.metadata.to_h).to eq(metadata)
        end

        context 'when metadata has strings for keys' do
          let(:metadata) { { 'some_meta' => 1 } }

          it 'includes metadata with symbolized keys' do
            expect(serialized_record_to_event.metadata.to_h).to eq(some_meta: 1)
          end
        end
      end

      describe '#serialized_record_to_event', 'with events class remapping specified' do
        subject do
          described_class
            .new(events_class_remapping: events_class_remapping)
            .serialized_record_to_event(serialized_record)
        end
        let(:serialized_record_event_type) { 'EventNameBeforeRefactor' }
        let(:events_class_remapping) do
          { 'EventNameBeforeRefactor' => SomethingHappenedJSON.name }
        end

        it { is_expected.to eq(domain_event) }
      end
    end
  end
end
