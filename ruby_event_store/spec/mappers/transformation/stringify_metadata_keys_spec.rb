# frozen_string_literal: true

require "spec_helper"
require "json"

module RubyEventStore
  module Mappers
    module Transformation
      ::RSpec.describe StringifyMetadataKeys do
        let(:time) { Time.now.utc }
        let(:uuid) { SecureRandom.uuid }
        let(:record) do
          Record.new(
            event_id: uuid,
            metadata: JSON.parse(JSON.dump({ some: "meta" })),
            data: JSON.parse(JSON.dump({ some: "value" })),
            event_type: "TestEvent",
            timestamp: time,
            valid_at: time
          )
        end
        let(:changed_record) do
          Record.new(
            event_id: uuid,
            metadata: {
              some: "meta"
            },
            data: JSON.parse(JSON.dump({ some: "value" })),
            event_type: "TestEvent",
            timestamp: time,
            valid_at: time
          )
        end

        specify "#dump" do
          result = StringifyMetadataKeys.new.dump(changed_record)
          expect(result).to eq(record)
          expect(result.metadata.keys.map(&:class).uniq).to eq([String])
        end

        specify "#load" do
          result = StringifyMetadataKeys.new.load(changed_record)
          expect(result).to eq(record)
          expect(result.metadata.keys.map(&:class).uniq).to eq([String])
        end
      end
    end
  end
end
