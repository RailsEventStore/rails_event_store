require 'spec_helper'

module RubyEventStore::ROM::Repositories
  RSpec.describe EventStreams do
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
    let(:default_stream) { RubyEventStore::Stream.new('stream') }
    let(:default_stream2) { RubyEventStore::Stream.new('stream2') }
    let(:global_stream) { RubyEventStore::Stream.new('all') }

    specify '#create saves with position' do
      events.create([
        SRecord.new(event_id: id1 = SecureRandom.uuid),
        SRecord.new(event_id: id2 = SecureRandom.uuid)
      ])
      
      event_streams.create(default_stream, id1, position: 2)
      event_streams.create(default_stream, id2, position: 1)

      results = events.read(:forward, default_stream)

      expect(results.size).to eq(2)
      expect(results.map(&:event_id)).to eq([id2, id1])
      
      results = events.read(:backward, default_stream)

      expect(results.size).to eq(2)
      expect(results.map(&:event_id)).to eq([id1, id2])
    end
  
    specify "#delete removes events from stream" do
      events.create([
        SRecord.new(event_id: id1 = SecureRandom.uuid),
        SRecord.new(event_id: id2 = SecureRandom.uuid)
      ], stream: default_stream)
      
      events.create([
        SRecord.new(event_id: SecureRandom.uuid),
        SRecord.new(event_id: SecureRandom.uuid)
      ], stream: default_stream2)
      
      results = events.read(:forward, default_stream)
      
      expect(results.size).to eq(2)
      expect(results.map(&:event_id)).to eq([id1, id2])

      result = event_streams.event_streams.where(stream: default_stream.name).count
      
      expect(result).to eq(2)

      event_streams.delete(default_stream)
      
      result = event_streams.event_streams.where(stream: default_stream.name).count
      
      expect(result).to eq(0)

      results = events.read(:forward, default_stream)

      expect(results.size).to eq(0)

      results = events.read(:forward, default_stream2)

      expect(results.size).to eq(2)

      results = events.read(:forward, global_stream)

      expect(results.size).to eq(4)
    end
  
    specify "#all lists all stream names" do
      events.create([
        SRecord.new(event_id: id1 = SecureRandom.uuid),
        SRecord.new(event_id: id2 = SecureRandom.uuid)
      ], stream: default_stream)
      
      events.create([
        SRecord.new(event_id: SecureRandom.uuid),
        SRecord.new(event_id: SecureRandom.uuid)
      ], stream: default_stream2)
      
      results = event_streams.all
      
      expect(results.size).to eq(3)
      expect(results).to eq([
        global_stream,
        default_stream,
        default_stream2])
    end
  end
end
