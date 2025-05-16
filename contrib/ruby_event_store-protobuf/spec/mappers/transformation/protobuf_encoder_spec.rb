# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Protobuf
    module Mappers
      module Transformation
        ::RSpec.describe ProtobufEncoder do
          include ProtobufHelper
          let(:time) { Time.new.utc }
          let(:event_id) { "f90b8848-e478-47fe-9b4a-9f2a1d53622b" }
          let(:metadata) do
            {
              one: 1,
              two: 2.0,
              three: true,
              four: Date.new(2018, 4, 17),
              five: "five",
              six: Time.utc(2018, 12, 13, 11),
              seven: true,
              eight: false,
              nein: nil,
              ten: {
                some: "hash",
                with: {
                  nested: "values",
                },
              },
              eleven: [1, 2, 3],
              timestamp: time,
              valid_at: time,
            }
          end
          let(:data) { ResTesting::OrderCreated.new(customer_id: 123, order_id: "K3THNX9") }
          let(:domain_event) do
            RubyEventStore::Protobuf::Proto.new(
              event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
              data: data,
              metadata: metadata,
            )
          end

          specify "#dump raises error when no data" do
            record =
              Record.new(
                event_id: domain_event.event_id,
                metadata: domain_event.metadata.to_h,
                data: nil,
                event_type: domain_event.event_type,
                timestamp: time,
                valid_at: time,
              )
            expect { ProtobufEncoder.new.dump(record) }.to raise_error(ProtobufEncodingFailed)
          end

          specify "#dump raises error when wrong data" do
            record =
              Record.new(
                event_id: domain_event.event_id,
                metadata: domain_event.metadata.to_h,
                data: {
                },
                event_type: domain_event.event_type,
                timestamp: time,
                valid_at: time,
              )

            expect { ProtobufEncoder.new.dump(record) }.to raise_error(ProtobufEncodingFailed)
          end

          specify "#dump" do
            record = ProtoEvent.new.dump(domain_event)
            result = ProtobufEncoder.new.dump(record)
            expect(result).to be_a(Record)
            expect(result.event_id).to eq(event_id)
            expect(result.data).not_to be_empty
            expect(result.metadata).not_to be_empty
            expect(result.event_type).to eq("res_testing.OrderCreated")
            expect(result.timestamp).to eq(time)
            expect(result.valid_at).to eq(time)
          end

          specify "#load returns event instance in data attribute" do
            record = ProtoEvent.new.dump(domain_event)
            dump = ProtobufEncoder.new.dump(record)
            result = ProtobufEncoder.new.load(dump)
            expect(result).to be_a(Record)
            expect(result.event_id).to eq(domain_event.event_id)
            expect(result.data).to eq(data)
            expect(result.metadata).to eq(metadata.reject { |k, _| %i[timestamp valid_at].include?(k) })
            expect(result.timestamp).to eq(time)
            expect(result.valid_at).to eq(time)
          end
        end
      end
    end
  end
end
