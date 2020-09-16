# frozen_string_literal: true

require 'spec_helper'
require 'ruby_event_store/spec/mapper_lint'

SomethingHappenedJSON = Class.new(RubyEventStore::Event)

module RubyEventStore
  module Mappers
    RSpec.describe JSONMapper do
      it_behaves_like :mapper, described_class.new, TimeEnrichment.with(SomethingHappenedJSON.new)

      let(:time) { Time.now.utc }
      let(:data) { { some_attribute: 5 } }
      let(:metadata) { { some_meta: 1 } }
      let(:event_id) { SecureRandom.uuid }
      let(:record_event_type) { SomethingHappenedJSON.name }
      let(:domain_event) do
        TimeEnrichment.with(
          SomethingHappenedJSON.new(
            event_id: event_id,
            data:     data,
            metadata: metadata,
          )
        )
      end
      let(:record) do
        Record.new(
          event_id:   event_id,
          data:       data,
          metadata:   metadata,
          event_type: record_event_type,
          timestamp:  time,
          valid_at:   time,
        )
      end

      describe '#event_to_record' do
        subject do
          described_class.new.event_to_record(domain_event)
        end

        it { is_expected.to be_a(Record) }
        it { is_expected.to have_attributes(event_id: record.event_id) }
        it { is_expected.to have_attributes(data: record.data) }
        it { is_expected.to have_attributes(metadata: record.metadata) }
        it { is_expected.to have_attributes(event_type: record.event_type) }
      end

      describe '#record_to_event' do
        subject(:record_to_event) do
          described_class.new.record_to_event(record)
        end

        it { is_expected.to eq(domain_event) }
        it { is_expected.to be_a(SomethingHappenedJSON) }
        it { is_expected.to have_attributes(event_id: domain_event.event_id) }
        it { is_expected.to have_attributes(data: domain_event.data) }
        it 'includes the expected metadata' do
          expect(record_to_event.metadata.to_h).to eq(metadata.merge(timestamp: time, valid_at: time))
        end

        context 'when metadata has strings for keys' do
          let(:metadata) { { 'some_meta' => 1 } }

          it 'includes metadata with symbolized keys' do
            expect(record_to_event.metadata.to_h).to eq(some_meta: 1, timestamp: time, valid_at: time)
          end
        end
      end

      describe '#record_to_event', 'with events class remapping specified' do
        subject do
          described_class
            .new(events_class_remapping: events_class_remapping)
            .record_to_event(record)
        end
        let(:record_event_type) { 'EventNameBeforeRefactor' }
        let(:events_class_remapping) do
          { 'EventNameBeforeRefactor' => SomethingHappenedJSON.name }
        end

        it { is_expected.to eq(domain_event) }
      end
    end
  end
end
