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

    specify "#delete removes events from stream" do
      events.create([
        SRecord.new(event_id: id1 = SecureRandom.uuid),
      ], stream_name: 'stream')
      
      results = events.read(:forward, 'stream')

      expect(results.size).to eq(1)
      expect(results[0].event_id).to eq(id1)

      results = event_streams.delete('stream')

      expect(results.size).to eq(1)

      results = events.read(:forward, 'stream')

      expect(results.size).to eq(0)
    end
  end
end
