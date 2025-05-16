# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Mappers
    ::RSpec.describe Pipeline do
      specify "#initialize - default values" do
        pipe = Pipeline.new
        expect(pipe.transformations.map(&:class)).to eq [Transformation::DomainEvent]
      end

      specify "#initialize - custom edge mappers" do
        domain_mapper = Object.new
        pipe = Pipeline.new(to_domain_event: domain_mapper)
        expect(pipe.transformations).to eq [domain_mapper]
      end

      specify "#initialize - custom edge mappers" do
        domain_mapper = Object.new
        transformation_1 = Object.new
        transformation_2 = Object.new
        pipe = Pipeline.new(transformation_1, transformation_2, to_domain_event: domain_mapper)
        expect(pipe.transformations).to eq [domain_mapper, transformation_1, transformation_2]
      end

      specify "#initialize - single transformation" do
        domain_mapper = Object.new
        transformation_ = Object.new
        pipe = Pipeline.new(transformation_, to_domain_event: domain_mapper)
        expect(pipe.transformations).to eq [domain_mapper, transformation_]
      end

      specify "#initialize - change in transformations not allowed" do
        pipe = Pipeline.new
        expect { pipe.transformations << Object.new }.to raise_error(RuntimeError)
      end

      specify "#dump" do
        domain_mapper = Transformation::DomainEvent.new
        transformation_1 = Transformation::SymbolizeMetadataKeys.new
        transformation_2 = Transformation::StringifyMetadataKeys.new
        pipe = Pipeline.new(transformation_1, transformation_2, to_domain_event: domain_mapper)
        event = TestEvent.new
        record1 =
          Record.new(
            event_id: event.event_id,
            data: {
              item: 1,
            },
            metadata: "",
            event_type: "TestEvent",
            timestamp: Time.now.utc,
            valid_at: Time.now.utc,
          )
        record2 =
          Record.new(
            event_id: event.event_id,
            data: {
              item: 2,
            },
            metadata: "",
            event_type: "TestEvent",
            timestamp: Time.now.utc,
            valid_at: Time.now.utc,
          )
        expect(domain_mapper).to receive(:dump).with(event).and_return(record1)
        expect(transformation_1).to receive(:dump).with(record1).and_return(record2)
        expect(transformation_2).to receive(:dump).with(record2)
        expect { pipe.dump(event) }.not_to raise_error
      end

      specify "#dump" do
        domain_mapper = Transformation::DomainEvent.new
        transformation_1 = Transformation::SymbolizeMetadataKeys.new
        transformation_2 = Transformation::StringifyMetadataKeys.new
        pipe = Pipeline.new(transformation_1, transformation_2, to_domain_event: domain_mapper)
        record =
          Record.new(
            event_id: SecureRandom.uuid,
            data: "",
            metadata: "",
            event_type: "TestEvent",
            timestamp: Time.now.utc,
            valid_at: Time.now.utc,
          )
        record1 =
          Record.new(
            event_id: record.event_id,
            data: {
              item: 1,
            },
            metadata: "",
            event_type: "TestEvent",
            timestamp: Time.now.utc,
            valid_at: Time.now.utc,
          )
        record2 =
          Record.new(
            event_id: record.event_id,
            data: {
              item: 2,
            },
            metadata: "",
            event_type: "TestEvent",
            timestamp: Time.now.utc,
            valid_at: Time.now.utc,
          )
        expect(transformation_2).to receive(:load).with(record).and_return(record1)
        expect(transformation_1).to receive(:load).with(record1).and_return(record2)
        expect(domain_mapper).to receive(:load).with(record2)
        expect { pipe.load(record) }.not_to raise_error
      end
    end
  end
end
