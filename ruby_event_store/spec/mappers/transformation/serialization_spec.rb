require 'spec_helper'
require 'yaml'
require 'json'

module RubyEventStore
  module Mappers
    module Transformation
      RSpec.describe Serialization do
        let(:uuid)   { SecureRandom.uuid }
        let(:serialized) {
          Item.new(
            event_id:   uuid,
            data:       "---\n:some: value\n",
            metadata:   "---\n:some: meta\n",
            event_type: 'TestEvent',
          )
        }
        let(:item) {
          Item.new(
            event_id:   uuid,
            data:       { some: 'value' },
            metadata:   { some: 'meta' },
            event_type: 'TestEvent',
          )
        }

        specify "#initialize" do
          expect(Serialization.new.serializer).to eq(YAML)
          expect(Serialization.new(serializer: JSON).serializer).to eq(JSON)
        end

        specify "#dump" do
          expect(Serialization.new.dump(item)).to eq(serialized)
        end

        specify "#load" do
          expect(Serialization.new.load(serialized)).to eq(item)
        end
      end
    end
  end
end
