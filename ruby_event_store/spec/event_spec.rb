require 'spec_helper'

module Test
  TestCreated = Class.new(RubyEventStore::Event)
  TestDeleted = Class.new(RubyEventStore::Event)
end

module RubyEventStore
  RSpec.describe Event do

    specify 'default values' do
      event = Test::TestCreated.new
      expect(event.event_id).to_not           be_nil
      expect(event.data).to_not               be_nil
      expect(event.metadata).to_not           be_nil
      expect(event.data.to_h).to              eq({})
      expect(event.metadata.to_h).to          eq({})
      expect(event.timestamp).to              be_nil
    end

    specify 'constructor attributes are used as event data' do
      event = Test::TestCreated.new(data: {sample: 123})
      expect(event.event_id).to_not  be_nil
      expect(event.data[:sample]).to eq(123)
      expect(event.data).to          eq({sample: 123})
      expect(event.metadata.to_h).to eq({})
      expect(event.timestamp).to     be_nil
    end

    specify 'constructor event_id attribute is used as event id' do
      event = Test::TestCreated.new(event_id: 234)
      expect(event.event_id).to eq("234")
      expect(event.data).to     eq({})
      expect(event.metadata.to_h).to eq({})
    end

    specify 'constructor metadata attribute is used as event metadata (with timestamp changed)' do
      timestamp = Time.utc(2016, 3, 10, 15, 20)
      event = Test::TestCreated.new(metadata: {created_by: 'Someone', timestamp: timestamp})
      expect(event.event_id).to_not          be_nil
      expect(event.data).to                  eq({})
      expect(event.timestamp).to             eq(timestamp)
      expect(event.metadata[:created_by]).to eq('Someone')
    end

    specify 'for empty data it initializes instance with default values' do
      event = Test::TestCreated.new
      expect(event.event_id).to_not  be_nil
      expect(event.data).to          eq({})
      expect(event.metadata.to_h).to eq({})
    end

    specify 'UUID should be String' do
      event_1 = Test::TestCreated.new({event_id: 1})
      event_2 = Test::TestCreated.new
      expect(event_1.event_id).to be_an_instance_of(String)
      expect(event_2.event_id).to be_an_instance_of(String)
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

    specify 'two events are equal if their attributes are equal' do
      event_data = { foo: 'bar' }
      event_metadata = { timestamp: Time.now }
      event = Test::TestCreated.new(event_id: '1', data: event_data, metadata: event_metadata)
      same_event = Test::TestCreated.new(event_id: '1', data: event_data, metadata: event_metadata)
      expect(event).to eq(same_event)
    end

    specify 'two events are not equal if their payload is different' do
      event_data = { foo: 'bar' }
      event_metadata = { timestamp: Time.now }
      event = Test::TestCreated.new(event_id: '1', data: event_data, metadata: event_metadata)
      different_event = Test::TestCreated.new(event_id: '1', data: event_data.merge(price: 123), metadata: event_metadata)
      expect(event).not_to eq(different_event)
    end

    specify 'two events are not equal if their types are different' do
      TestDeleted = Class.new(RubyEventStore::Event)
      event_metadata = { timestamp: Time.now }
      event = Test::TestCreated.new(event_id: '1', metadata: event_metadata)
      different_event = TestDeleted.new(event_id: '1', metadata: event_metadata)
      expect(event).not_to eq(different_event)
    end

    specify 'an event and a random object are different' do
      event = Test::TestCreated.new
      object = Object.new
      expect(event).not_to eq(object)
    end

    specify 'convert to hash' do
      hash = {
          data: { data: 'sample' },
          event_id: 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd',
          metadata: { meta: 'test'},
      }
      event = Test::TestCreated.new(hash)
      expect(event.to_h).to eq(hash.merge(type: 'Test::TestCreated'))
    end

    specify 'only events with the same class, event_id & data are equal' do
      event_1 = Test::TestCreated.new
      event_2 = Test::TestCreated.new
      expect(event_1 == event_2).to be_falsey

      event_1 = Test::TestCreated.new(event_id: 1, data: {test: 123})
      event_2 = Test::TestDeleted.new(event_id: 1, data: {test: 123})
      expect(event_1 == event_2).to be_falsey

      event_1 = Test::TestCreated.new(event_id: 1, data: {test: 123})
      event_2 = Test::TestCreated.new(event_id: 1, data: {test: 234})
      expect(event_1 == event_2).to be_falsey

      event_1 = Test::TestCreated.new(event_id: 1, data: {test: 123}, metadata: {does: 'not matter'})
      event_2 = Test::TestCreated.new(event_id: 1, data: {test: 123}, metadata: {really: 'yes'})
      expect(event_1 == event_2).to be_truthy
    end

    specify "#hash" do
      expect(Event.new(event_id: "doh").hash).to eq(Event.new(event_id: "doh").hash)
      expect(Event.new(event_id: "doh").hash).not_to eq(Event.new(event_id: "bye").hash)

      expect(
        Event.new(event_id: "doh", data: {}).hash
      ).to eq(Event.new(event_id: "doh", data: {}).hash)

      expect(
        Event.new(event_id: "doh", data: {}).hash
      ).not_to eq(Event.new(event_id: "doh", data: {a: 1}).hash)

      klass = Class.new(Event)
      expect(
        klass.new(event_id: "doh").hash
      ).not_to eq(Event.new(event_id: "doh").hash)
      expect(
        klass.new(event_id: "doh").hash
      ).to eq(klass.new(event_id: "doh").hash)

      expect({
        klass.new(event_id: "doh") => :YAY
      }[ klass.new(event_id: "doh") ]).to eq(:YAY)
      expect(Set.new([
        klass.new(event_id: "doh")
      ])).to eq(Set.new([klass.new(event_id: "doh")]))

      expect(klass.new(event_id: "doh").hash).not_to eq([
        klass,
        "doh",
        {}
      ].hash)
    end

    specify "uses Metadata and its restrictions" do
      expect do
        Test::TestCreated.new(metadata: {key: Object.new})
      end.to raise_error(ArgumentError)
    end

    specify "correlation_id && causation_id" do
      e0 = Event.new(event_id: "doh")
      expect(e0.event_id).to       eq("doh")
      expect(e0.correlation_id).to eq("doh")
      expect(e0.causation_id).to   eq("doh")

      e1 = Event.new(event_id: "yay")
      e1.correlate_with(e0)
      expect(e1.event_id).to       eq("yay")
      expect(e1.correlation_id).to eq("doh")
      expect(e1.causation_id).to   eq("doh")

      e2 = Event.new(event_id: "jeb")
      e2.correlate_with(e1)
      expect(e2.event_id).to       eq("jeb")
      expect(e2.correlation_id).to eq("doh")
      expect(e2.causation_id).to   eq("yay")

      event = Event.new(event_id: "mem", metadata: {correlation_id: "cor", causation_id: "cau"})
      expect(event.event_id).to       eq("mem")
      expect(event.correlation_id).to eq("cor")
      expect(event.causation_id).to   eq("cau")
    end

  end
end
