require 'spec_helper'
require 'ruby_event_store/rom/memory'
require 'ruby_event_store/spec/rom/relations/events_lint'

module RubyEventStore
  module ROM
  module Memory
  RSpec.describe Relations::Events do
    let(:rom_helper) { SpecHelper.new }

    subject(:relation) { rom_container.relations[:events] }

    let(:env) { rom_helper.env }
    let(:rom_container) { env.rom_container }
    let(:rom_db) { rom_container.gateways[:default] }

    around(:each) do |example|
      rom_helper.run_lifecycle { example.run }
    end

    it_behaves_like :events_relation, Relations::Events

    specify '#for_stream_entries filters events on :event_id in stream entries' do
      events = [
        { event_id: SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now },
        { event_id: id2 = SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now },
        { event_id: id3 = SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now }
      ]

      stream_entries = [
        { id: 1, event_id: id2 },
        { id: 2, event_id: id3 }
      ]

      relation.command(:create).call(events)

      expect(relation.for_stream_entries(nil, stream_entries).to_a.map { |e| e[:event_id] }).to eq([id2, id3])
    end

    specify '#pluck returns an array with single value for each tuple' do
      events = [
        { event_id: id1 = SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now },
        { event_id: id2 = SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now },
        { event_id: id3 = SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now }
      ]

      relation.command(:create).call(events)

      expect(relation.to_a.size).to eq(3)
      expect(relation.pluck(:event_id)).to eq([id1, id2, id3])
      expect(relation.by_event_id(events[0][:event_id]).to_a.size).to eq(1)
      expect(relation.by_event_id(events[0][:event_id]).pluck(:event_id)).to eq([id1])
    end

    specify '#insert raises errors' do
      events = [
        { event_id: id1 = SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now },
        { event_id: id2 = SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now },
      ]

      relation.command(:create).call(events)

      conflicting_event_id =
        { event_id: id1, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now }

      expect do
        relation.insert(conflicting_event_id)
      end.to raise_error do |ex|
        expect(ex).to be_a(RubyEventStore::ROM::TupleUniquenessError)
        expect(ex.message).to eq("Uniquness violated for event_id (\"#{id1}\")")
      end
    end
  end
  end
  end
end
