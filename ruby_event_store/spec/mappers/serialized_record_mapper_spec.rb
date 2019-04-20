require 'spec_helper'
require 'yaml'
require 'json'

module RubyEventStore
  module Mappers
    RSpec.describe SerializedRecordMapper do
      let(:uuid)   { SecureRandom.uuid }
      let(:record) { SerializedRecord.new(
        event_id: uuid,
        data: "---\n:some: value\n",
        metadata: "---\n:some: meta\n",
        event_type: 'TestEvent',
      ) }
      let(:item)   {
        TransformationItem.new(
          event_id:   uuid,
          data:       {some: 'value'},
          metadata:   {some: 'meta'},
          event_type: 'TestEvent',
        )
      }

      specify "#initialize" do
        expect(SerializedRecordMapper.new.serializer).to eq(YAML)
        expect(SerializedRecordMapper.new(serializer: JSON).serializer).to eq(JSON)
      end

      specify "#dump" do
        expect(SerializedRecordMapper.new.dump(item)).to eq(record)
      end

      specify "#load" do
        expect(SerializedRecordMapper.new.load(record)).to eq(item)
      end
    end
  end
end

