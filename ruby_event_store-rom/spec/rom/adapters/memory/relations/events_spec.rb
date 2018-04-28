require 'spec_helper'
require 'ruby_event_store/rom/memory'
require 'ruby_event_store/spec/rom/relations/events_lint'

module RubyEventStore::ROM::Memory
  RSpec.describe Relations::Events do
    let(:rom_helper) { SpecHelper.new }

    subject(:relation) { container.relations[:events] }

    let(:env) { rom_helper.env }
    let(:container) { env.container }
    let(:rom_db) { container.gateways[:default] }

    around(:each) do |example|
      rom_helper.run_lifecycle { example.run }
    end

    it_behaves_like :events_relation, Relations::Events

    specify '#for_stream_entries filters events on :event_id in stream entries' do
      events = [
        {id: id1 = SecureRandom.uuid, event_type: "TestEvent", data: "", metadata: "", created_at: Time.now},
        {id: id2 = SecureRandom.uuid, event_type: "TestEvent", data: "", metadata: "", created_at: Time.now},
        {id: id3 = SecureRandom.uuid, event_type: "TestEvent", data: "", metadata: "", created_at: Time.now}
      ]
  
      stream_entries = [
        {id: 1, event_id: id2},
        {id: 2, event_id: id3}
      ]
  
      relation.command(:create).call(events)
  
      expect(relation.for_stream_entries(nil, stream_entries).to_a.map { |e| e[:id] }).to eq([id2, id3])
    end

    specify '#pluck returns an array with single value for each tuple' do
      events = [
        {id: id1 = SecureRandom.uuid, event_type: "TestEvent", data: "", metadata: "", created_at: Time.now},
        {id: id2 = SecureRandom.uuid, event_type: "TestEvent", data: "", metadata: "", created_at: Time.now},
        {id: id3 = SecureRandom.uuid, event_type: "TestEvent", data: "", metadata: "", created_at: Time.now}
      ]
  
      relation.command(:create).call(events)
  
      expect(relation.to_a.size).to eq(3)
      expect(relation.pluck(:id)).to eq([id1, id2, id3])
      expect(relation.by_pk(events[0][:id]).to_a.size).to eq(1)
      expect(relation.by_pk(events[0][:id]).pluck(:id)).to eq([id1])
    end
  end
end
