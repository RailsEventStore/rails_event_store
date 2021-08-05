require 'spec_helper'
require 'json'
require 'ruby_event_store/spec/mapper_lint'

SomethingHappened = Class.new(RubyEventStore::Event)

module RubyEventStore
  module Mappers

    class MapperWithTypes < PipelineMapper
      def initialize
        super(Pipeline.new(
          Transformation::PreserveTypes.new
            .register(
              Time,
              serializer: ->(v) { v.iso8601(9) },
              deserializer: ->(v) { Time.iso8601(v) },
            )
            .register(
              Date,
              serializer: ->(v) { v.iso8601 },
              deserializer: ->(v) { Date.iso8601(v) },
            )
            .register(
              DateTime,
              serializer: ->(v) { v.iso8601(9) },
              deserializer: ->(v) { DateTime.iso8601(v) },
            ),
          Transformation::SymbolizeMetadataKeys.new,
        ))
      end
    end


    RSpec.describe MapperWithTypes do
      let(:time)         { Time.new(2021, 8, 5, 12, 00, 00).utc }
      let(:date)         { Date.new(2021, 8, 5) }
      let(:datetime)     { DateTime.new(2021, 8, 5, 12, 00, 00) }
      let(:data)         {
        {
          some_attribute: 5,
          time: time,
          date: date,
          datetime: datetime,
        }
      }
      let(:serialized_data) {
        {
          some_attribute: 5,
          time: "2021-08-05T10:00:00.000000000Z",
          date: "2021-08-05",
          datetime: "2021-08-05T12:00:00.000000000+00:00",
        }
      }
      let(:metadata)     { {some_meta: 1} }
      let(:event_id)     { SecureRandom.uuid }
      let(:domain_event) { TimeEnrichment.with(SomethingHappened.new(data: data, metadata: metadata, event_id: event_id), timestamp: time, valid_at: time) }

      it_behaves_like :mapper, MapperWithTypes.new, TimeEnrichment.with(SomethingHappened.new)

      specify '#event_to_record returns transformed record' do
        record = subject.event_to_record(domain_event)
        expect(record).to            be_a Record
        expect(record.event_id).to   eq event_id
        expect(record.data).to       eq serialized_data
        expect(record.metadata).to   eq({
          some_meta: 1,
          types: {
            data: {
              some_attribute: 'Integer',
              time: 'Time',
              date: 'Date',
              datetime: 'DateTime',
              _res_symbol_keys: ['some_attribute', 'time', 'date', 'datetime'],
            },
            metadata: {
              some_meta: 'Integer',
              _res_symbol_keys: ['some_meta'],
            },
          },
        })
        expect(record.event_type).to eq "SomethingHappened"
        expect(record.timestamp).to  eq(time)
        expect(record.valid_at).to   eq(time)
      end

      specify '#record_to_event returns event instance with restored types' do
        record = Record.new(
          event_id:   domain_event.event_id,
          data:       serialized_data,
          metadata:   {
            some_meta: 1,
            types: {
              data: {
                some_attribute: 'Integer',
                time: 'Time',
                date: 'Date',
                datetime: 'DateTime',
                _res_symbol_keys: ['some_attribute', 'time', 'date', 'datetime'],
              },
              metadata: {
                some_meta: 'Integer',
                _res_symbol_keys: ['some_meta'],
              },
            },
          },
          event_type: SomethingHappened.name,
          timestamp:  time,
          valid_at:   time,
        )
        event = subject.record_to_event(record)
        expect(event).to               eq(domain_event)
        expect(event.event_id).to      eq domain_event.event_id
        expect(event.data).to          eq(data)
        expect(event.metadata.to_h).to eq(metadata.merge(timestamp: time, valid_at: time))
        expect(event.metadata[:timestamp]).to eq(time)
        expect(event.metadata[:valid_at]).to  eq(time)
      end

      specify '#record_to_event returns event instance without restored types when no types metadata are present' do
        record = Record.new(
          event_id:   domain_event.event_id,
          data:       serialized_data,
          metadata:   { some_meta: 1 },
          event_type: SomethingHappened.name,
          timestamp:  time,
          valid_at:   time,
        )
        event = subject.record_to_event(record)
        expect(event.event_id).to      eq domain_event.event_id
        expect(event.data).to          eq(serialized_data)
        expect(event.metadata.to_h).to eq(metadata.merge(timestamp: time, valid_at: time))
        expect(event.metadata[:timestamp]).to eq(time)
        expect(event.metadata[:valid_at]).to  eq(time)
      end

      specify 'metadata keys are symbolized' do
        record = Record.new(
          event_id:   domain_event.event_id,
          data:       { some_attribute: 5 },
          metadata:   stringify({ some_meta: 1}),
          event_type: SomethingHappened.name,
          timestamp:  time,
          valid_at:   time,
        )
        event = subject.record_to_event(record)
        expect(event.metadata.to_h).to eq(metadata.merge(timestamp: time, valid_at: time))
        expect(event.metadata[:timestamp]).to eq(time)
        expect(event.metadata[:valid_at]).to  eq(time)
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
