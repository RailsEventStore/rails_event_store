# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Protobuf
    module Mappers
      module Transformation
        ::RSpec.describe ProtobufNestedStructMetadata do
          include ProtobufHelper

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
                  nested: "values"
                }
              },
              eleven: [1, 2, 3]
            }
          end
          let(:uuid) { SecureRandom.uuid }
          let(:record) do
            Record.new(
              event_id: uuid,
              event_type: "SomeEvent",
              data: "anything",
              metadata: metadata,
              timestamp: Time.new.utc,
              valid_at: Time.new.utc
            )
          end

          specify "#dump" do
            dump = ProtobufNestedStructMetadata.new.dump(record)
            expect(dump.event_id).to eq(record.event_id)
            expect(dump.data).not_to be_empty
            expect(dump.metadata).not_to be_empty
          end

          specify "#load" do
            dump = ProtobufNestedStructMetadata.new.dump(record)
            load = ProtobufNestedStructMetadata.new.load(dump)
            expect(load).to eq(record)
          end
        end
      end
    end
  end
end
