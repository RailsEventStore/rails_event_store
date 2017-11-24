module RubyEventStore

  RSpec.describe SerializedRecord do
    let(:event_id) { "event_id" }
    let(:data) { "data" }
    let(:metadata) { "metadata" }
    let(:event_type) { "event_type" }

    specify 'constructor accept all arguments and returns frozen instance' do
      record = described_class.new(event_id: event_id, data: data, metadata: metadata, event_type: event_type)
      expect(record.event_id).to be event_id
      expect(record.metadata).to be metadata
      expect(record.data).to be data
      expect(record.event_type).to be event_type
      expect(record.frozen?).to be true
    end

    specify 'constructor raised SerializedRecord::StringsRequired when argument is not a String' do
      [["string", 1, 1, 1],
       [1, "string", 1, 1],
       [1, 1, "string", 1],
       [1, 1, 1, "string"]].each do |sample|
        event_id, data, metadata, event_type = sample
        expect do
          described_class.new(event_id: event_id, data: data, metadata: metadata, event_type: event_type)
        end.to raise_error SerializedRecord::StringsRequired
      end
    end
  end
end
