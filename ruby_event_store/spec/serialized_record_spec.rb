require 'spec_helper'

module RubyEventStore

  RSpec.describe SerializedRecord do
    let(:event_id)   { "event_id" }
    let(:data)       { "data" }
    let(:metadata)   { "metadata" }
    let(:event_type) { "event_type" }

    specify 'constructor accept all arguments and returns frozen instance' do
      record = described_class.new(event_id: event_id, data: data, metadata: metadata, event_type: event_type)
      expect(record.event_id).to   be event_id
      expect(record.metadata).to   be metadata
      expect(record.data).to       be data
      expect(record.event_type).to be event_type
      expect(record.frozen?).to    be true
    end

    specify 'constructor raised SerializedRecord::StringsRequired when argument is not a String' do
      [[1, 1, 1, 1],
       [1, "string", "string", "string"],
       ["string", "string", "string", 1]].each do |sample|
        event_id, data, metadata, event_type = sample
        expect do
          described_class.new(event_id: event_id, data: data, metadata: metadata, event_type: event_type)
        end.to raise_error SerializedRecord::StringsRequired
      end
    end

    specify "in-equality" do
      [
        ["a", "a", "a", "a"],
        ["b", "a", "a", "a"],
        ["a", "b", "a", "a"],
        ["a", "a", "b", "a"],
        ["a", "a", "a", "b"],
      ].permutation(2).each do |one, two|
        a = SerializedRecord.new(event_id: one[0], data: one[1], metadata: one[2], event_type: one[3])
        b = SerializedRecord.new(event_id: two[0], data: two[1], metadata: two[2], event_type: two[3])
        c = Class.new(SerializedRecord).new(event_id: one[0], data: one[1], metadata: one[2], event_type: one[3])
        expect(a).not_to eq(b)
        expect(a).not_to eql(b)
        expect(a.hash).not_to eq(b.hash)
        h = {a => :val}
        expect(h[b]).to be_nil

        expect(a).not_to eq(c)
        expect(a).not_to eql(c)
        expect(a.hash).not_to eq(c.hash)
        h = {a => :val}
        expect(h[c]).to be_nil
      end
    end

    specify "equality" do
      a = SerializedRecord.new(event_id: "a", data: "b", metadata: "c", event_type: "d")
      b = SerializedRecord.new(event_id: "a", data: "b", metadata: "c", event_type: "d")
      expect(a).to eq(b)
      expect(a).to eql(b)
      expect(a.hash).to eql(b.hash)
      h = {a => :val}
      expect(h[b]).to eq(:val)
    end

    specify "hash" do
      a = SerializedRecord.new(event_id: "a", data: "b", metadata: "c", event_type: "d")
      expect(a.hash).not_to eq([SerializedRecord, "a", "b", "c", "d"].hash)
    end

    specify "to_h" do
      a = SerializedRecord.new(event_id: "a", data: "b", metadata: "c", event_type: "d")
      expect(a.to_h).to eq({
        event_id: "a",
        data: "b",
        metadata: "c",
        event_type: "d",
      })
    end

    specify 'constructor raised when required args are missing' do
      expect do
        described_class.new
      end.to raise_error ArgumentError
    end
  end
end

