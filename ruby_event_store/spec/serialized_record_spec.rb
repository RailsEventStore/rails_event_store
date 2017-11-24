module RubyEventStore
  module Mappers
    RSpec.describe SerializedRecord do
      let(:event_id)   { double(:event_id) }
      let(:data)       { double(:data) }
      let(:metadata)   { double(:metadata) }
      let(:event_type) { double(:event_type) }

      specify do
        record = described_class.new(event_id: event_id, data: data, metadata: metadata, event_type: event_type)
        expect(record.event_id).to   be event_id
        expect(record.metadata).to   be metadata
        expect(record.data).to       be data
        expect(record.event_type).to be event_type
        expect(record.frozen?).to    be true
      end
    end
  end
end
