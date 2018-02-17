require_relative 'events_pb.rb'

module RubyEventStore
  module Mappers
    RSpec.describe Protobuf do
      let(:event_id)     { "f90b8848-e478-47fe-9b4a-9f2a1d53622b" }
      let(:domain_event) do
        ResTesting::OrderCreated.new(
          event_id: event_id,
          customer_id: 123,
          order_id: "K3THNX9",
        )
      end
      let(:proto) { "\n$f90b8848-e478-47fe-9b4a-9f2a1d53622b\x12\aK3THNX9\x18{" }

      specify '#event_to_serialized_record returns proto serialized record' do
        record = subject.event_to_serialized_record(domain_event)
        expect(record).to            be_a(SerializedRecord)
        expect(record.event_id).to   eq(event_id)
        expect(record.data).to       eq(proto)
        expect(record.metadata).to   eq("")
        expect(record.event_type).to eq("ResTesting::OrderCreated")
      end

      specify '#serialized_record_to_event returns event instance' do
        record = SerializedRecord.new(
          event_id:   event_id,
          data:       proto,
          metadata:   "",
          event_type: "ResTesting::OrderCreated"
        )
        event = subject.serialized_record_to_event(record)
        expect(event).to              eq(domain_event)
        expect(event.event_id).to     eq(event_id)
        expect(event.customer_id).to  eq(123)
        expect(event.order_id).to     eq("K3THNX9")
      end

      specify '#event_to_serialized_record can define getter for event_id' do
        subject = described_class.new(
          event_id_getter: :order_id,
        )
        record = subject.event_to_serialized_record(domain_event)
        expect(record.event_id).to   eq("K3THNX9")
        expect(record.data).to       eq(proto)
      end

      specify '#serialized_record_to_event is using events class remapping' do
        subject = described_class.new(
          events_class_remapping: {'EventNameBeforeRefactor' => "ResTesting::OrderCreated"}
        )
        record = SerializedRecord.new(
          event_id:   event_id,
          data:       proto,
          metadata:   "",
          event_type: "EventNameBeforeRefactor",
        )
        event = subject.serialized_record_to_event(record)
        expect(event).to eq(domain_event)
      end

    end
  end
end
