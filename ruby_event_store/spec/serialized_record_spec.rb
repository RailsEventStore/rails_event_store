module RubyEventStore
  module Mappers
    RSpec.describe SerializedRecord do
      let(:id)         { double(:id) }
      let(:data)       { double(:data) }
      let(:metadata)   { double(:metadata) }
      let(:event_type) { double(:event_type) }

      specify '#event_to_serialized_record returns YAML serialized record' do
        record = described_class.new(id: id, data: data, metadata: metadata, event_type: event_type)
        expect(record.id).to         be id
        expect(record.metadata).to   be metadata
        expect(record.data).to       be data
        expect(record.event_type).to be event_type
        expect(record.frozen?).to    be true
      end
    end
  end
end
