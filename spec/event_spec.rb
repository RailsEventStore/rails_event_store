require 'spec_helper'

module Test
  class TestCreated < RailsEventStore::Event
  end
end

module RailsEventStore
  describe Client do

    specify 'for empty data it initializes instance with default values' do
      event = Test::TestCreated.new
      expect(event.event_type).to eq  'TestCreated'
      expect(event.event_id).to_not   be_nil
      expect(event.metadata).to       be_nil
      expect(event.data).to           be_nil
    end

    specify 'UUID should be unique' do
      event_1 = Test::TestCreated.new
      event_2 = Test::TestCreated.new
      expect(event_1.event_id).to_not eq(event_2.event_id)
    end

    specify 'UUID should look like an UUID' do
      event = Test::TestCreated.new
      uuid_regexp = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      expect(event.event_id).to match(uuid_regexp)
    end

    specify 'convert to hash' do
      event_data = {
          event_type: 'OrderCreated',
          data: { data: 'sample' },
          event_id: 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd',
          metadata: { meta: 'test'}
      }
      event = Test::TestCreated.new(event_data)
      expect(event.to_h[:event_type]).to eq 'OrderCreated'
      expect(event.to_h[:event_id]).to eq 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd'
      expect(event.to_h[:metadata]).to eq({ meta: 'test'})
      expect(event.to_h[:data]).to eq({ data: 'sample' })
    end

    specify 'convert to hash with default Time metadata' do
      event_data = {
          event_type: 'OrderCreated',
          data: { data: 'sample' },
          event_id: 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd',
      }
      event = Test::TestCreated.new(event_data)
      expect(event.to_h[:event_type]).to eq 'OrderCreated'
      expect(event.to_h[:event_id]).to eq 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd'
      expect(event.to_h[:metadata][:published_at]).to be_a Time
      expect(event.to_h[:metadata][:published_at].zone).to eq 'UTC'
      expect(event.to_h[:data]).to eq({ data: 'sample' })
    end
  end
end
