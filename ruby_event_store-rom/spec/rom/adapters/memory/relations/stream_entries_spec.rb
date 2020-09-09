require 'spec_helper'
require 'ruby_event_store/rom/memory'
require 'ruby_event_store/spec/rom/relations/stream_entries_lint'

module RubyEventStore
  module ROM
  module Memory
  RSpec.describe Relations::StreamEntries do
    let(:rom_helper) { SpecHelper.new }

    it_behaves_like :stream_entries_relation, Relations::StreamEntries

    specify '#insert raises errors' do
      relation = rom_helper.env.rom_container.relations[:stream_entries]

      stream_entries = [
        { stream: 'stream', position: 0, event_id: id1 = SecureRandom.uuid },
        { stream: 'stream', position: 1, event_id: SecureRandom.uuid },
        { stream: 'stream', position: 2, event_id: SecureRandom.uuid }
      ]

      relation.command(:create).call(stream_entries)

      conflicting_event_id = { stream: 'stream', position: 3, event_id: id1, created_at: Time.now }

      expect(relation.to_a.size).to eq(3)
      expect do
        relation.insert(conflicting_event_id)
      end.to raise_error do |ex|
        expect(ex).to be_a(RubyEventStore::ROM::TupleUniquenessError)
        expect(ex.message).to eq("Uniquness violated for stream (\"stream\") and event_id (\"#{id1}\")")
      end

      conflicting_position = { stream: 'stream', position: 2, event_id: SecureRandom.uuid, created_at: Time.now }

      expect do
        relation.insert(conflicting_position)
      end.to raise_error do |ex|
        expect(ex).to be_a(RubyEventStore::ROM::TupleUniquenessError)
        expect(ex.message).to eq('Uniquness violated for stream ("stream") and position (2)')
      end
    end
  end
  end
  end
end
