# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'ruby_event_store/spec/mapper_lint'

module RubyEventStore
  module Mappers

    class MapperWithTypes < PipelineMapper
      def initialize
        super(Pipeline.new(
          Transformation::PreserveTypes.new
            .register(
              Symbol,
              serializer: ->(v) { v.to_s },
              deserializer: ->(v) { v.to_sym },
            )
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


    ::RSpec.describe MapperWithTypes do
      let(:time)         { Time.new(2021, 8, 5, 12, 00, 00) }
      let(:utc_time)     { Time.new(2021, 8, 5, 12, 00, 00).utc }
      let(:date)         { Date.new(2021, 8, 5) }
      let(:datetime)     { DateTime.new(2021, 8, 5, 12, 00, 00) }
      let(:data)         {
        {
          some_attribute: 5,
          symbol: :any,
          time: time,
          utc_time: utc_time,
          date: date,
          datetime: datetime,
        }
      }
      let(:serialized_data) {
        {
          'some_attribute' => 5,
          'symbol' => 'any',
          'time' => time.iso8601(9),
          'utc_time' => utc_time.iso8601(9),
          'date' => date.iso8601,
          'datetime' => datetime.iso8601(9),
        }
      }
      let(:metadata)     { {some_meta: 1} }
      let(:event_id)     { SecureRandom.uuid }
      let(:event) { TimeEnrichment.with(TestEvent.new(data: data, metadata: metadata, event_id: event_id), timestamp: time, valid_at: time) }

      it_behaves_like 'mapper', MapperWithTypes.new, TimeEnrichment.with(TestEvent.new)

      specify '#event_to_record returns transformed record' do
        record = subject.event_to_record(event)
        expect(record).to            be_a Record
        expect(record.event_id).to   eq event_id
        expect(record.data).to       eq serialized_data
        expect(record.metadata).to   eq({
          some_meta: 1,
          types: {
            data: {
              some_attribute: ['Symbol', 'Integer'],
              symbol: ['Symbol', 'Symbol'],
              time: ['Symbol', 'Time'],
              utc_time: ['Symbol', 'Time'],
              date: ['Symbol', 'Date'],
              datetime: ['Symbol', 'DateTime'],
            },
            metadata: {
              some_meta: ['Symbol', 'Integer'],
            },
          },
        })
        expect(record.event_type).to eq 'TestEvent'
        expect(record.timestamp).to  eq(time)
        expect(record.valid_at).to   eq(time)
      end

      specify '#record_to_event returns event instance with restored types' do
        record = Record.new(
          event_id:   event.event_id,
          data:       serialized_data,
          metadata:   {
            some_meta: 1,
            types: {
              data: {
                some_attribute: ['Symbol', 'Integer'],
                symbol: ['Symbol', 'Symbol'],
                time: ['Symbol', 'Time'],
                utc_time: ['Symbol', 'Time'],
                date: ['Symbol', 'Date'],
                datetime: ['Symbol', 'DateTime'],
              },
              metadata: {
                some_meta: ['Symbol', 'Integer'],
              },
            },
          },
          event_type: TestEvent.name,
          timestamp:  time,
          valid_at:   time,
        )
        event_ = subject.record_to_event(record)
        expect(event_).to               eq(event)
        expect(event_.event_id).to      eq event.event_id
        expect(event_.data).to          eq(data)
        expect(event_.metadata.to_h).to eq(metadata.merge(timestamp: time, valid_at: time))
        expect(event_.metadata[:timestamp]).to eq(time)
        expect(event_.metadata[:valid_at]).to  eq(time)
      end

      specify '#record_to_event returns event instance without restored types when no types metadata are present' do
        record = Record.new(
          event_id:   event.event_id,
          data:       serialized_data,
          metadata:   { some_meta: 1 },
          event_type: TestEvent.name,
          timestamp:  time,
          valid_at:   time,
        )
        event_ = subject.record_to_event(record)
        expect(event_.event_id).to      eq event.event_id
        expect(event_.data).to          eq(serialized_data)
        expect(event_.metadata.to_h).to eq(metadata.merge(timestamp: time, valid_at: time))
        expect(event_.metadata[:timestamp]).to eq(time)
        expect(event_.metadata[:valid_at]).to  eq(time)
      end

      specify 'metadata keys are symbolized' do
        record = Record.new(
          event_id:   event.event_id,
          data:       { some_attribute: 5 },
          metadata:   stringify({ some_meta: 1}),
          event_type: TestEvent.name,
          timestamp:  time,
          valid_at:   time,
        )
        event_ = subject.record_to_event(record)
        expect(event_.metadata.to_h).to eq(metadata.merge(timestamp: time, valid_at: time))
        expect(event_.metadata[:timestamp]).to eq(time)
        expect(event_.metadata[:valid_at]).to  eq(time)
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
