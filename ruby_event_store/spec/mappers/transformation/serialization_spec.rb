require 'spec_helper'
require 'yaml'
require 'json'

module RubyEventStore
  module Mappers
    module Transformation
      RSpec.describe Serialization do
        let(:uuid)   { SecureRandom.uuid }
        let(:serialized) {
          Record.new(
            event_id: uuid,
            data: "---\n:some: value\n",
            metadata: "---\n:some: meta\n",
            event_type: 'TestEvent',
          )
        }
        let(:record)   {
          Record.new(
            event_id:   uuid,
            data:       {some: 'value'},
            metadata:   {some: 'meta'},
            event_type: 'TestEvent',
          )
        }

        specify "#initialize" do
          expect(Serialization.new.serializer).to eq(YAML)
          expect(Serialization.new(serializer: JSON).serializer).to eq(JSON)
        end

        specify "#dump" do
          expect(Serialization.new.dump(record)).to eq(serialized)
        end

        specify "#load" do
          expect(Serialization.new.load(serialized)).to eq(record)
        end
      end
    end
  end
end
