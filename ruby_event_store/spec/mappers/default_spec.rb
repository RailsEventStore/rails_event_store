# frozen_string_literal: true

require "spec_helper"
require "json"
require "ruby_event_store/spec/mapper_lint"

SomethingHappened = Class.new(RubyEventStore::Event)

module RubyEventStore
  module Mappers
    ::RSpec.describe Default do
      let(:time) { Time.now.utc }
      let(:data) { { some_attribute: 5 } }
      let(:metadata) { { some_meta: 1 } }
      let(:event_id) { SecureRandom.uuid }
      let(:event) do
        TimeEnrichment.with(
          SomethingHappened.new(data: data, metadata: metadata, event_id: event_id),
          timestamp: time,
          valid_at: time,
        )
      end

      it_behaves_like "mapper", Default.new, TimeEnrichment.with(SomethingHappened.new)

      specify "#event_to_record returns transformed record" do
        record = subject.event_to_record(event)
        expect(record).to be_a Record
        expect(record.event_id).to eq event_id
        expect(record.data).to eq({ some_attribute: 5 })
        expect(record.metadata).to eq({ some_meta: 1 })
        expect(record.event_type).to eq "SomethingHappened"
        expect(record.timestamp).to eq(time)
        expect(record.valid_at).to eq(time)
      end

      specify "#record_to_event returns event instance" do
        record =
          Record.new(
            event_id: event.event_id,
            data: {
              some_attribute: 5,
            },
            metadata: {
              some_meta: 1,
            },
            event_type: SomethingHappened.name,
            timestamp: time,
            valid_at: time,
          )
        event_ = subject.record_to_event(record)
        expect(event_).to eq(event)
        expect(event_.event_id).to eq event.event_id
        expect(event_.data).to eq(data)
        expect(event_.metadata.to_h).to eq(metadata.merge(timestamp: time, valid_at: time))
        expect(event_.metadata[:timestamp]).to eq(time)
        expect(event_.metadata[:valid_at]).to eq(time)
      end

      specify "#record_to_event its using events class remapping" do
        subject = Default.new(events_class_remapping: { "EventNameBeforeRefactor" => "SomethingHappened" })
        record =
          Record.new(
            event_id: event.event_id,
            data: {
              some_attribute: 5,
            },
            metadata: {
              some_meta: 1,
            },
            event_type: "EventNameBeforeRefactor",
            timestamp: time,
            valid_at: time,
          )
        event_ = subject.record_to_event(record)
        expect(event_).to eq(event)
      end

      specify "metadata keys are symbolized" do
        record =
          Record.new(
            event_id: event.event_id,
            data: {
              some_attribute: 5,
            },
            metadata: stringify({ some_meta: 1 }),
            event_type: SomethingHappened.name,
            timestamp: time,
            valid_at: time,
          )
        event_ = subject.record_to_event(record)
        expect(event_).to eq(event)
        expect(event_.event_id).to eq event.event_id
        expect(event_.data).to eq(data)
        expect(event_.metadata.to_h).to eq(metadata.merge(timestamp: time, valid_at: time))
        expect(event_.metadata[:timestamp]).to eq(time)
        expect(event_.metadata[:valid_at]).to eq(time)
      end

      private

      def stringify(hash)
        hash.each_with_object({}) { |(k, v), memo| memo[k.to_s] = v }
      end
    end
  end
end
