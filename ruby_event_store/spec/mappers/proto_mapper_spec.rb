require 'spec_helper'

module RubyEventStore
  module Mappers
    RSpec.describe ProtoMapper do
      include ProtobufHelper
      before(:each) { require_protobuf_dependencies }

      let(:event_id)     { "f90b8848-e478-47fe-9b4a-9f2a1d53622b" }
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

      specify '#dump raises error when no data' do
        item = DomainEventProtoMapper.new.dump(domain_event).merge(data: nil)
        expect do
          ProtoMapper.new.dump(item)
        end.to raise_error(ProtobufEncodingFailed)
      end

      specify '#dump raises error when wrong data' do
        item = DomainEventProtoMapper.new.dump(domain_event).merge(data: {})

        expect do
          ProtoMapper.new.dump(item)
        end.to raise_error(ProtobufEncodingFailed)
      end

      specify '#dump' do
        item = DomainEventProtoMapper.new.dump(domain_event)
        result = ProtoMapper.new.dump(item)
        expect(result).to              be_a(TransformationItem)
        expect(result.event_id).to     eq(event_id)
        expect(result.data).not_to     be_empty
        expect(result.metadata).not_to be_empty
        expect(result.event_type).to   eq("res_testing.OrderCreated")
      end

      specify '#load returns event instance in data attribute' do
        require_protobuf_dependencies

        item = DomainEventProtoMapper.new.dump(domain_event)
        dump = ProtoMapper.new.dump(item)
        result = ProtoMapper.new.load(dump)
        expect(result).to                be_a(TransformationItem)
        expect(result.event_id).to       eq(domain_event.event_id)
        expect(result.data).to           eq(data)
      end
    end
  end
end
