# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module Mappers
    module Transformation
      ::RSpec.describe Upcast do
        let(:time) { Time.now.utc }
        let(:uuid) { SecureRandom.uuid }

        let(:record_v1) do
          Record.new(
            event_id: uuid,
            metadata: {
              some: "meta",
            },
            data: [{ some: "value" }],
            event_type: "record.v1",
            timestamp: time,
            valid_at: time,
          )
        end
        let(:record_v2) do
          Record.new(
            event_id: uuid,
            metadata: {
              some: "meta",
            },
            data: {
              as_hash: [{ some: "value" }],
            },
            event_type: "record.v2",
            timestamp: time,
            valid_at: time,
          )
        end
        let(:record_v3) do
          Record.new(
            event_id: uuid,
            metadata: {
              some: "meta",
            },
            data: {
              as_hash: [{ some: "value" }],
              other_as_well: {
              },
            },
            event_type: "record.v3",
            timestamp: time,
            valid_at: time,
          )
        end
        let(:upcast_map) do
          {
            "record.v1" =>
              lambda do |r|
                Record.new(
                  event_id: r.event_id,
                  metadata: r.metadata,
                  timestamp: r.timestamp,
                  valid_at: r.valid_at,
                  event_type: "record.v2",
                  data: {
                    as_hash: r.data,
                  },
                )
              end,
            "record.v2" =>
              lambda do |r|
                Record.new(
                  event_id: r.event_id,
                  metadata: r.metadata,
                  timestamp: r.timestamp,
                  valid_at: r.valid_at,
                  event_type: "record.v3",
                  data: r.data.merge(other_as_well: {}),
                )
              end,
          }
        end

        specify "#dump" do
          expect(Upcast.new(upcast_map).dump(record_v1)).to eq(record_v1)
          expect(Upcast.new(upcast_map).dump(record_v2)).to eq(record_v2)
          expect(Upcast.new(upcast_map).dump(record_v3)).to eq(record_v3)
        end

        specify "#load" do
          expect(Upcast.new(upcast_map).load(record_v1)).to eq(record_v3)
          expect(Upcast.new(upcast_map).load(record_v2)).to eq(record_v3)
          expect(Upcast.new(upcast_map).load(record_v3.dup)).to eq(record_v3)
        end
      end
    end
  end
end
