require 'spec_helper'
require 'ruby_event_store/spec/mapper_lint'

module RubyEventStore
  RSpec.describe Proto do
    include ProtobufHelper

    before(:each) { require_protobuf_dependencies }

    specify 'equality' do
      event_1 = RubyEventStore::Proto.new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        ),
        metadata: {
          time: Time.new(2018, 12, 13, 11 ),
        }
      )
      event_2 = RubyEventStore::Proto.new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        ),
        metadata: {
          time: Time.new(2018, 12, 13, 11 ),
        }
      )
      expect(event_1).to eq(event_2)
    end

    specify 'equality - metadata does not need to be the same' do
      event_1 = RubyEventStore::Proto.new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        ),
        metadata: {
          time: Time.new(2018, 12, 13, 11 ),
        }
      )
      event_2 = RubyEventStore::Proto.new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        ),
      )
      expect(event_1).to eq(event_2)
    end

    specify 'equality - class must be the same' do
      event_1 = Class.new(RubyEventStore::Proto).new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
          ),
        metadata: {
          time: Time.new(2018, 12, 13, 11 ),
        }
      )
      event_2 = RubyEventStore::Proto.new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
          ),
        metadata: {
          time: Time.new(2018, 12, 13, 11 ),
        }
      )
      expect(event_1).not_to eq(event_2)
    end


    specify 'equality - event_id must be the same' do
      event_1 = RubyEventStore::Proto.new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        ),
        metadata: {
          time: Time.new(2018, 12, 13, 11 ),
        }
      )
      event_2 = RubyEventStore::Proto.new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622c",
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        ),
        metadata: {
          time: Time.new(2018, 12, 13, 11 ),
        }
      )
      expect(event_1).not_to eq(event_2)
    end

    specify 'equality - data must be the same' do
      event_1 = RubyEventStore::Proto.new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
          ),
        metadata: {
          time: Time.new(2018, 12, 13, 11 ),
        }
      )
      event_2 = RubyEventStore::Proto.new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        data: ResTesting::OrderCreated.new(
          customer_id: 124,
          order_id: "K3THNX9",
        ),
        metadata: {
          time: Time.new(2018, 12, 13, 11 ),
        }
      )
      expect(event_1).not_to eq(event_2)
    end

    specify 'event type' do
      event = RubyEventStore::Proto.new(
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        ),
      )
      expect(event.event_type).to eq("res_testing.OrderCreated")
    end

    specify 'defaults' do
      event = RubyEventStore::Proto.new(data: "One")
      expect(event.event_id).to match(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/)
      expect(event.metadata.to_h).to eq({})
      expect(event.data).to eq("One")
    end

    specify 'metadata' do
      event = RubyEventStore::Proto.new(data: nil, metadata: {one: 1})
      expect(event.metadata[:one]).to eq(1)
      expect do
        event.metadata['doh']
      end.to raise_error(ArgumentError)
    end

    it_behaves_like :correlatable, Proto
  end

  module Mappers
    RSpec.describe Protobuf do
      include ProtobufHelper
      extend  ProtobufHelper

      before(:each) { require_protobuf_dependencies }

      let(:time)     { Time.now.utc }
      let(:event_id) { "f90b8848-e478-47fe-9b4a-9f2a1d53622b" }
      let(:metadata) { {
        one: 1,
        two: 2.0,
        three: true,
        four: Date.new(2018, 4, 17),
        five: "five",
        six: Time.utc(2018, 12, 13, 11 ),
        seven: true,
        eight: false,
        nein: nil,
        ten: {some: 'hash', with: {nested: 'values'}},
        eleven: [1,2,3],
        timestamp: time,
        valid_at: time
      } }
      let(:data) do
        ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        )
      end
      let(:domain_event) do
        RubyEventStore::Proto.new(
          event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
          data: data,
          metadata: metadata,
        )
      end

      require_protobuf_dependencies do
        it_behaves_like :mapper, Protobuf.new,
          TimeEnrichment.with(
            RubyEventStore::Proto.new(
              data: ResTesting::OrderCreated.new(
                customer_id: 123,
                order_id: "K3THNX9",
              )
            )
          )
      end

      specify '#event_to_record returns proto serialized record' do
        record = Protobuf.new.event_to_record(domain_event)
        expect(record).to              be_a(Record)
        expect(record.event_id).to     eq(event_id)
        expect(record.data).not_to     be_empty
        expect(record.metadata).not_to be_empty
        expect(record.event_type).to   eq("res_testing.OrderCreated")
        expect(record.timestamp).to    eq(time)
        expect(record.valid_at).to     eq(time)
      end

      specify '#record_to_event returns event instance' do
        record = Protobuf.new.event_to_record(domain_event)
        event  = Protobuf.new.record_to_event(record)
        expect(event).to                eq(domain_event)
        expect(event.event_id).to       eq(event_id)
        expect(event.data).to           eq(data)
        expect(event.metadata.to_h).to  eq(metadata)
        expect(event.timestamp).to      eq(time)
        expect(event.valid_at).to       eq(time)
      end

      specify '#record_to_event is using events class remapping' do
        subject = Protobuf.new(
          events_class_remapping: {'res_testing.OrderCreatedBeforeRefactor' => "res_testing.OrderCreated"}
        )
        record = Record.new(
          event_id:   "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
          data:       "",
          metadata:   "",
          event_type: "res_testing.OrderCreatedBeforeRefactor",
          timestamp:  time,
          valid_at:   time,
        )
        event = subject.record_to_event(record)
        expect(event.data.class).to eq(ResTesting::OrderCreated)
        expect(event.event_type).to eq("res_testing.OrderCreated")
        expect(event.timestamp).to  eq(time)
        expect(event.valid_at).to   eq(time)
      end
    end
  end
end
