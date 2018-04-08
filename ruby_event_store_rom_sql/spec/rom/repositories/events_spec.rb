require 'spec_helper'

module RubyEventStore::ROM::Repositories
  RSpec.describe Events do
    include SchemaHelper

    around(:each) do |example|
      begin
        establish_database_connection
        load_database_schema
        example.run
      ensure
        drop_database
      end
    end

    let(:events) { Events.new(rom) }
    let(:event_streams) { EventStreams.new(rom) }

    specify '#create links events to stream and also GLOBAL_STREAM' do
      events.create([
        SRecord.new(event_id: id1 = SecureRandom.uuid),
        SRecord.new(event_id: id2 = SecureRandom.uuid),
      ], stream_name: 'stream', expected_version: RubyEventStore::ExpectedVersion.auto)
      
      results = events.read(:forward, "all")

      expect(results.size).to eq(2)
      expect(results.map(&:event_id)).to eq([id1, id2])
    end
  
    specify '#link links events to stream but not GLOBAL_STREAM' do
      events.create([
        SRecord.new(event_id: id1 = SecureRandom.uuid),
        SRecord.new(event_id: id2 = SecureRandom.uuid),
      ])
      
      events.link([id1, id2], "stream", RubyEventStore::ExpectedVersion.none)

      results = events.read(:forward, "stream")

      expect(results.size).to eq(2)
      expect(results.map(&:event_id)).to eq([id1, id2])

      results = events.read(:forward, "all")

      expect(results.size).to eq(0)
    end
  
    specify '#link links events with proper position' do
      events.create([
        SRecord.new(event_id: id1 = SecureRandom.uuid),
        SRecord.new(event_id: id2 = SecureRandom.uuid),
      ])
      
      results = events.link([id1, id2], "auto", RubyEventStore::ExpectedVersion.auto)
      
      expect(results.size).to eq(2)
      expect(results[0].event_id).to eq(id1)
      expect(results[0].position).to eq(0)
      expect(results[1].event_id).to eq(id2)
      expect(results[1].position).to eq(1)
      
      results = events.link([id1, id2], "none", RubyEventStore::ExpectedVersion.none)
      
      expect(results.size).to eq(2)
      expect(results[0].event_id).to eq(id1)
      expect(results[0].position).to eq(0)
      expect(results[1].event_id).to eq(id2)
      expect(results[1].position).to eq(1)
      
      events.create([
        SRecord.new(event_id: id3 = SecureRandom.uuid),
        SRecord.new(event_id: id4 = SecureRandom.uuid),
      ])
      
      expect do
        events.link([id3, id4], "none", RubyEventStore::ExpectedVersion.none)
      end.to raise_error(::ROM::SQL::UniqueConstraintError)
      
      results = events.link([id3, id4], "auto", RubyEventStore::ExpectedVersion.auto)
      
      expect(results.size).to eq(2)
      expect(results[0].event_id).to eq(id3)
      expect(results[0].position).to eq(2)
      expect(results[1].event_id).to eq(id4)
      expect(results[1].position).to eq(3)

      results = events.link([id3, id4], "auto2", RubyEventStore::ExpectedVersion.auto)
      
      expect(results.size).to eq(2)
      expect(results[0].event_id).to eq(id3)
      expect(results[0].position).to eq(0)
      expect(results[1].event_id).to eq(id4)
      expect(results[1].position).to eq(1)

      results = events.link([id1, id2], "any", RubyEventStore::ExpectedVersion.any)
      
      expect(results.size).to eq(2)
      expect(results[0].event_id).to eq(id1)
      expect(results[0].position).to eq(nil)
      expect(results[1].event_id).to eq(id2)
      expect(results[1].position).to eq(nil)

      results = events.link([id1, id2], "all", RubyEventStore::ExpectedVersion.any)
      
      expect(results.size).to eq(0)
    end
  
    specify "#link with event ID that doesn't exist raises EventNotFound" do
      expect do
        events.link(["bogus-event-id"], "stream", RubyEventStore::ExpectedVersion.any)
      end.to raise_error do |err|
        expect(err).to be_a(RubyEventStore::EventNotFound)
        expect(err.event_id).to eq("bogus-event-id")
        expect(err.message).to eq("Event not found: bogus-event-id")
      end
    end
  
    specify "#link with expected version not :any for GLOBAL_STREAM raises InvalidExpectedVersion" do
      events.create([
        SRecord.new(event_id: id1 = SecureRandom.uuid)
      ], stream_name: 'stream', expected_version: RubyEventStore::ExpectedVersion.auto)
      
      expect do
        events.link([id1], "all", RubyEventStore::ExpectedVersion.auto, global_stream: true)
      end.to raise_error(RubyEventStore::InvalidExpectedVersion)
    end
  
    specify "#read direction that isn't valid raises ArgumentError" do
      expect { events.read(nil, "stream") }.to raise_error do |err|
        expect(err).to be_a(ArgumentError)
        expect(err.message).to eq("Direction must be :forward or :backward")
      end
    end

    specify "#read returns an array" do
      results = events.read(:forward, "stream")

      expect(results).to be_an(Array)
      expect(results.size).to eq(0)
    end

    specify '#read finds events in the proper order' do
      events.create([
        SRecord.new(event_id: id1 = SecureRandom.uuid),
        SRecord.new(event_id: id2 = SecureRandom.uuid),
      ], stream_name: 'stream', expected_version: RubyEventStore::ExpectedVersion.auto)
      
      results = events.read(:forward, "stream")

      expect(results.map(&:event_id)).to eq([id1, id2])
      
      results = events.read(:backward, "stream")

      expect(results.map(&:event_id)).to eq([id2, id1])
      
      results = events.read(:forward, "all")

      expect(results.map(&:event_id)).to eq([id1, id2])
      
      results = events.read(:backward, "all")

      expect(results.map(&:event_id)).to eq([id2, id1])
    end
  
    specify '#read finds events after :from' do
      events.create([
        SRecord.new(event_id: id1 = SecureRandom.uuid),
        SRecord.new(event_id: id2 = SecureRandom.uuid),
      ], stream_name: 'stream', expected_version: RubyEventStore::ExpectedVersion.none)
      
      results = events.read(:forward, "stream", from: id1)

      expect(results.size).to eq(1)
      expect(results[0].event_id).to eq(id2)
    end
  
    specify '#read finds all events from :head' do
      events.create([
        SRecord.new(event_id: id1 = SecureRandom.uuid),
        SRecord.new(event_id: id2 = SecureRandom.uuid),
      ], stream_name: 'stream', expected_version: RubyEventStore::ExpectedVersion.none)
      
      results = events.read(:forward, "stream")

      expect(results.size).to eq(2)
      expect(results.map(&:event_id)).to eq([id1, id2])
    end
  
    specify '#read limits to one result' do
      events.create([
        SRecord.new(event_id: id1 = SecureRandom.uuid),
        SRecord.new(event_id: id2 = SecureRandom.uuid),
      ], stream_name: 'stream', expected_version: RubyEventStore::ExpectedVersion.none)
      
      results = events.read(:forward, "stream", limit: 1)

      expect(results.size).to eq(1)
      expect(results[0].event_id).to eq(id1)
      
      results = events.read(:backward, "stream", limit: 1)

      expect(results.size).to eq(1)
      expect(results[0].event_id).to eq(id2)
    end
  
    specify "#read doesn't limit for nil" do
      events.create([
        SRecord.new(event_id: SecureRandom.uuid),
        SRecord.new(event_id: SecureRandom.uuid),
      ], stream_name: 'stream', expected_version: RubyEventStore::ExpectedVersion.none)
      
      results = events.read(:forward, "stream", limit: nil)

      expect(results.size).to eq(2)
    end
  
    specify "#read :from event that doesn't exist raises EventNotFound" do
      expect do
        events.read(:forward, "stream", from: "bogus-event-id")
      end.to raise_error do |err|
        expect(err).to be_a(RubyEventStore::EventNotFound)
        expect(err.event_id).to eq("bogus-event-id")
        expect(err.message).to eq("Event not found: bogus-event-id")
      end
    end

    specify "#read fetches stream with position ordering" do
      events.create([
        SRecord.new(event_id: id1 = SecureRandom.uuid),
        SRecord.new(event_id: id2 = SecureRandom.uuid),
        SRecord.new(event_id: id3 = SecureRandom.uuid)
      ])
      
      event_streams.create('stream', id1, position: 1)
      event_streams.create('stream', id2, position: 0)
      event_streams.create('stream', id3, position: 2)
      
      results = events.read(:forward, 'stream', limit: 3)

      expect(results.map(&:event_id)).to eq([id2, id1, id3])
      
      results = events.read(:backward, 'stream', limit: 3)

      expect(results.map(&:event_id)).to eq([id3, id1, id2])
    end
  
    specify "#read fetches GLOBAL_STREAM without position ordering" do
      events.create([
        SRecord.new(event_id: id1 = SecureRandom.uuid),
        SRecord.new(event_id: id2 = SecureRandom.uuid),
        SRecord.new(event_id: id3 = SecureRandom.uuid)
      ])
      
      event_streams.create('all', id1, position: 1)
      event_streams.create('all', id2, position: 0)
      event_streams.create('all', id3, position: 2)
      
      results = events.read(:forward, 'all', limit: 3)

      expect(results.map(&:event_id)).to eq([id1, id2, id3])
      
      results = events.read(:backward, 'all', limit: 3)

      expect(results.map(&:event_id)).to eq([id3, id2, id1])
    end
  
    specify "#fetch event retrieves SerializedRecord" do
      events.create([
        SRecord.new(event_id: SecureRandom.uuid),
        SRecord.new(event_id: id1 = SecureRandom.uuid),
        SRecord.new(event_id: SecureRandom.uuid)
      ], stream_name: 'stream')
      
      expect(events.fetch(id1)).to be_a(RubyEventStore::SerializedRecord)
      expect(events.fetch(id1).event_id).to eq(id1)
    end
  
    specify "#exist? returns a boolean if an event with the ID exists" do
      events.create([
        SRecord.new(event_id: SecureRandom.uuid),
        SRecord.new(event_id: id1 = SecureRandom.uuid),
        SRecord.new(event_id: SecureRandom.uuid)
      ], stream_name: 'stream')
      
      expect(events.exist?(id1)).to eq(true)
      expect(events.exist?("bogus-event-id")).to eq(false)
    end
  end
end
