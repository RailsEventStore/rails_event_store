require 'spec_helper'


module RubyEventStore
  RSpec.describe Proto do
    before(:each) do
      begin
        require_relative 'events_pb.rb'
        require 'protobuf_nested_struct'
      rescue LoadError => exc
        skip if exc.message == "cannot load such file -- google/protobuf_c"
      end
    end

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
      expect(copy.metadata.to_h).to eq(event.metadata.to_h)
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
      before(:each) do
        begin
          require_relative 'events_pb.rb'
          require 'protobuf_nested_struct'
        rescue LoadError => exc
          skip if exc.message == "cannot load such file -- google/protobuf_c"
        end
      end

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

      specify "initialize requires protobuf_nested_struct" do
        p = Protobuf.allocate
        def p.require(_name)
          raise LoadError
        end
        expect do
          p.send(:initialize)
        end.to raise_error(LoadError, "cannot load such file -- protobuf_nested_struct. Add protobuf_nested_struct gem to Gemfile")
      end

      specify '#event_to_serialized_record returns proto serialized record' do
        record = subject.event_to_serialized_record(domain_event)
        expect(record).to              be_a(SerializedRecord)
        expect(record.event_id).to     eq(event_id)
        expect(record.data).not_to     be_empty
        expect(record.metadata).not_to be_empty
        expect(record.event_type).to   eq("res_testing.OrderCreated")
      end

      specify '#serialized_record_to_event returns event instance' do
        record = subject.event_to_serialized_record(domain_event)
        event  = subject.serialized_record_to_event(record)
        expect(event).to                eq(domain_event)
        expect(event.event_id).to       eq(event_id)
        expect(event.data).to           eq(data)
        expect(event.metadata.to_h).to  eq(metadata)
      end

      specify '#serialized_record_to_event is using events class remapping' do
        subject = described_class.new(
          events_class_remapping: {'res_testing.OrderCreatedBeforeRefactor' => "res_testing.OrderCreated"}
        )
        record = SerializedRecord.new(
          event_id:   event_id,
          data:       "",
          metadata:   "",
          event_type: "res_testing.OrderCreatedBeforeRefactor",
        )
        event = subject.serialized_record_to_event(record)
        expect(event.data.class).to eq(ResTesting::OrderCreated)
        expect(event.type).to eq("res_testing.OrderCreated")
      end
    end
  end
end
