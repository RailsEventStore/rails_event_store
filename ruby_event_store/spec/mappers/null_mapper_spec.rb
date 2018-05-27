require 'spec_helper'

module RubyEventStore
  module Mappers
    RSpec.describe NullMapper do

      specify '#event_to_serialized_record returns provided event' do
        event = Object.new
        record = subject.event_to_serialized_record(event)
        expect(record).to eq event
      end

      specify '#serialized_record_to_event returns provided event' do
        record = Object.new
        event = subject.serialized_record_to_event(record)
        expect(event).to eq record
      end

      specify '#load_serialized_event returns provided serialized event' do
        serialized_event = {event_type: 'SomeEvent', event_id: '123', data: {some: 'data'}, metadata: { some: 'metadata'}}
        event = subject.load_serialized_event(serialized_event)
        expect(event).to eq serialized_event
      end

    end
  end
end
