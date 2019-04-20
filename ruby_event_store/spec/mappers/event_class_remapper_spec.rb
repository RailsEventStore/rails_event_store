require 'spec_helper'

module RubyEventStore
  module Mappers
    RSpec.describe EventClassRemapper do
      let(:uuid)  { SecureRandom.uuid }
      let(:item)  {
        TransformationItem.new(
          event_id:   uuid,
          metadata:   {some: 'meta'},
          data:       {some: 'value'},
          event_type: 'TestEvent',
        )
      }
      let(:changeable_item) { item.merge(event_type: 'EventNameBeforeRefactor') }
      let(:changed_item)    { item.merge(event_type: 'SomethingHappened') }
      let(:class_map) { {'EventNameBeforeRefactor' => 'SomethingHappened'} }

      specify "#dump" do
        expect(EventClassRemapper.new(class_map).dump(item)).to eq(item)
        expect(EventClassRemapper.new(class_map).dump(item)).to eq(item)
      end

      specify "#load" do
        expect(EventClassRemapper.new(class_map).load(item)).to eq(item)
        expect(EventClassRemapper.new(class_map).load(changeable_item)).to eq(changed_item)
      end
    end
  end
end
