require 'spec_helper'

module RubyEventStore
  module Mappers
    RSpec.describe Pipeline do

      specify '#initialize - default values' do
        pipe = Pipeline.new
        expect(pipe.transformations.map(&:class)).to eq [DomainEventMapper, SerializedRecordMapper]
      end

      specify '#initialize - custom edge mappers' do
        domain_mapper = Object.new
        record_mapper = Object.new
        pipe = Pipeline.new(to_domain_event: domain_mapper, to_serialized_record: record_mapper)
        expect(pipe.transformations).to eq [domain_mapper, record_mapper]
      end

      specify '#initialize - custom edge mappers' do
        domain_mapper = Object.new
        record_mapper = Object.new
        some_mapper1 = Object.new
        some_mapper2 = Object.new
        pipe = Pipeline.new(to_domain_event: domain_mapper, to_serialized_record: record_mapper, transformations: [some_mapper1, some_mapper2])
        expect(pipe.transformations).to eq [domain_mapper, some_mapper1, some_mapper2, record_mapper]
      end

      specify '#initialize - single transformation' do
        domain_mapper = Object.new
        record_mapper = Object.new
        some_mapper = Object.new
        pipe = Pipeline.new(to_domain_event: domain_mapper, to_serialized_record: record_mapper, transformations: some_mapper)
        expect(pipe.transformations).to eq [domain_mapper, some_mapper, record_mapper]
      end

      specify '#initialize - change in transformations not allowed' do
        pipe = Pipeline.new
        expect { pipe.transformations << Object.new}.to raise_error(FrozenError)
      end

      specify '#dump' do
        domain_mapper = DomainEventMapper.new
        record_mapper = SerializedRecordMapper.new
        some_mapper1 = SymbolizeMetadataKeys.new
        some_mapper2 = StringifyMetadataKeys.new
        pipe = Pipeline.new(to_domain_event: domain_mapper, to_serialized_record: record_mapper, transformations: [some_mapper1, some_mapper2])
        domain_event = TestEvent.new
        item1 = TransformationItem.new(event_id: domain_event.event_id, item: 1)
        item2 = TransformationItem.new(event_id: domain_event.event_id, item: 2)
        item3 = TransformationItem.new(event_id: domain_event.event_id, item: 3)
        expect(domain_mapper).to receive(:dump).with(domain_event).and_return(item1)
        expect(some_mapper1).to receive(:dump).with(item1).and_return(item2)
        expect(some_mapper2).to receive(:dump).with(item2).and_return(item3)
        expect(record_mapper).to receive(:dump).with(item3)
        expect{ pipe.dump(domain_event) }.not_to raise_error
      end

      specify '#dump' do
        domain_mapper = DomainEventMapper.new
        record_mapper = SerializedRecordMapper.new
        some_mapper1 = SymbolizeMetadataKeys.new
        some_mapper2 = StringifyMetadataKeys.new
        pipe = Pipeline.new(to_domain_event: domain_mapper, to_serialized_record: record_mapper, transformations: [some_mapper1, some_mapper2])
        record  = SerializedRecord.new(event_id: SecureRandom.uuid, data: '', metadata: '', event_type: 'TestEvent')
        item1 = TransformationItem.new(event_id: record.event_id, item: 1)
        item2 = TransformationItem.new(event_id: record.event_id, item: 2)
        item3 = TransformationItem.new(event_id: record.event_id, item: 3)
        expect(record_mapper).to receive(:load).with(record).and_return(item1)
        expect(some_mapper2).to receive(:load).with(item1).and_return(item2)
        expect(some_mapper1).to receive(:load).with(item2).and_return(item3)
        expect(domain_mapper).to receive(:load).with(item3)
        expect{ pipe.load(record) }.not_to raise_error
      end
    end
  end
end
