require 'spec_helper'

module RubyEventStore
  module Mappers
    RSpec.describe DomainEventMapper do
      let(:uuid)  { SecureRandom.uuid }
      let(:event) {
        TestEvent.new(event_id: uuid,
                      data: {some: 'value'},
                      metadata: {some: 'meta'})
      }
      let(:item)  {
        {
          event_id:   uuid,
          metadata:   {some: 'meta'},
          data:       {some: 'value'},
          event_type: 'TestEvent',
        }
      }

      specify "#dump" do
        expect(DomainEventMapper.new.dump(event)).to eq(item)
      end

      specify "#load" do
        loaded = DomainEventMapper.new.load(item)
        expect(loaded).to eq(event)
        expect(loaded.metadata.to_h).to eq(event.metadata.to_h)
      end
    end
  end
end
