require 'spec_helper'
require 'json'

module RubyEventStore
  module Mappers
    RSpec.describe StringifyMetadataKeys do
      let(:uuid)  { SecureRandom.uuid }
      let(:item)  {
        {
          event_id:   uuid,
          metadata:   JSON.parse(JSON.dump({some: 'meta'})),
          data:       JSON.parse(JSON.dump({some: 'value'})),
          event_type: 'TestEvent',
        }
      }
      let(:changed_item)  {
        {
          event_id:   uuid,
          metadata:   {some: 'meta'},
          data:       JSON.parse(JSON.dump({some: 'value'})),
          event_type: 'TestEvent',
        }
      }

      specify "#dump" do
        result = StringifyMetadataKeys.new.dump(changed_item)
        expect(result).to eq(item)
        expect(result[:metadata].keys.map(&:class).uniq).to eq([String])
      end

      specify "#load" do
        result = StringifyMetadataKeys.new.load(changed_item)
        expect(result).to eq(item)
        expect(result[:metadata].keys.map(&:class).uniq).to eq([String])
      end
    end
  end
end
