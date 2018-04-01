require 'spec_helper'
require_relative 'events_pb.rb'

module RubyEventStore
  RSpec.describe Proto do
    specify 'yaml serialization' do
      event = RubyEventStore::Proto.new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        ),
        metadata: {
          time: Time.new(2018, 12, 13, 11 ),
        }
      )
      copy = YAML.load(YAML.dump(event))
      expect(copy).to eq(event)
      expect(copy.metadata).to eq(event.metadata)
    end

    specify 'type' do
      event = RubyEventStore::Proto.new(
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        ),
      )
      expect(event.type).to eq("res_testing.OrderCreated")
    end

    specify 'defaults' do
      event = RubyEventStore::Proto.new(data: "One")
      expect(event.event_id).to match(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/)
      expect(event.metadata).to eq({})
      expect(event.data).to eq("One")
    end
  end

  module Mappers
    RSpec.describe Protobuf do
      let(:event_id)     { "f90b8848-e478-47fe-9b4a-9f2a1d53622b" }
      let(:domain_event) do
        RubyEventStore::Proto.new(
          event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
          data: ResTesting::OrderCreated.new(
            customer_id: 123,
            order_id: "K3THNX9",
          ),
          metadata: {
            time: Time.utc(2018, 12, 13, 11 ),
          }
        )
      end
      let(:proto) { "\n\aK3THNX9\x10{" }

      specify '#event_to_serialized_record returns proto serialized record' do
        record = subject.event_to_serialized_record(domain_event)
        expect(record).to            be_a(SerializedRecord)
        expect(record.event_id).to   eq(event_id)
        expect(record.data).to       eq(proto)
        expect(record.metadata).to   eq("---\n:time: 2018-12-13 11:00:00.000000000 Z\n")
        expect(record.event_type).to eq("res_testing.OrderCreated")
      end

      specify '#serialized_record_to_event returns event instance' do
        record = SerializedRecord.new(
          event_id:   event_id,
          data:       proto,
          metadata:   "---\n:time: 2018-12-13 11:00:00.000000000 Z\n",
          event_type: "res_testing.OrderCreated"
        )
        event = subject.serialized_record_to_event(record)
        expect(event).to              eq(domain_event)
        expect(event.event_id).to     eq(event_id)
        expect(event.data.customer_id).to  eq(123)
        expect(event.data.order_id).to     eq("K3THNX9")
        expect(event.metadata[:time]).to  eq(Time.utc(2018, 12, 13, 11 ))
      end

      specify '#serialized_record_to_event is using events class remapping' do
        subject = described_class.new(
          events_class_remapping: {'res_testing.OrderCreatedBeforeRefactor' => "res_testing.OrderCreated"}
        )
        record = SerializedRecord.new(
          event_id:   event_id,
          data:       proto,
          metadata:   "",
          event_type: "res_testing.OrderCreatedBeforeRefactor",
        )
        event = subject.serialized_record_to_event(record)
        expect(event).to eq(domain_event)
      end

    end
  end
end
