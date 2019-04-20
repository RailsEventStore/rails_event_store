require 'spec_helper'
require 'yaml'
require 'json'

module RubyEventStore
  module Mappers
    RSpec.describe SerializationMapper do
      let(:uuid)   { SecureRandom.uuid }
      let(:serialized) {
        TransformationItem.new(
          event_id: uuid,
          data: "---\n:some: value\n",
          metadata: "---\n:some: meta\n",
          event_type: 'TestEvent',
        )
      }
      let(:item)   {
        TransformationItem.new(
          event_id:   uuid,
          data:       {some: 'value'},
          metadata:   {some: 'meta'},
          event_type: 'TestEvent',
        )
      }

      specify "#initialize" do
        expect(SerializationMapper.new.serializer).to eq(YAML)
        expect(SerializationMapper.new(serializer: JSON).serializer).to eq(JSON)
      end

      specify "#dump" do
        expect(SerializationMapper.new.dump(item)).to eq(serialized)
      end

      specify "#load" do
        expect(SerializationMapper.new.load(serialized)).to eq(item)
      end
    end
  end
end

